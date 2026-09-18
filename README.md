# demo-deploy-terraform

Azure 共通基盤（ALZ 準拠 Hub-Spoke）を Terraform + Azure Verified Modules (AVM) で実装し、
GitHub Actions（OIDC / シークレットレス）で CI/CD を回すための検証リポジトリです。

## ディレクトリ構成

```
stacks/                     実行単位（ワーキングディレクトリ）
├── 10-policy/              Azure Policy 割り当て
├── 20-connectivity/        Hub VNet / Firewall / Bastion / Route Table / DDoS
├── 21-dns/                 Private DNS Zones / DNS Private Resolver
├── 22-gateway/             VNet Gateway (VPN / ExpressRoute)   ※dev なし
└── 40-management/          Log Analytics / Key Vault
    └── envs/{dev,stg,prd}/ terraform.tfvars（パラメータ）/ backend.hcl（State 接続先）
bootstrap/state-backend.sh  State 用ストレージ + NSP の初期構築
deployments.yml             CI/CD マトリクスの正本
.github/
├── actions/nsp-runner-access/  NSP へ runner IP を一時登録/削除する composite action
├── workflows/                  ci / cd / _terraform-apply / verify-oidc
└── CODEOWNERS
```

スタックは**ライフサイクル単位**で分割し、それぞれ独立して plan / apply できます。
環境差分はブランチではなく `envs/<環境>/terraform.tfvars` で表現します。

## 前提

- Terraform >= 1.10（CI は 1.14.4）
- Azure CLI (`az login`) もしくは GitHub Actions OIDC
- State は Azure Storage（スタックごとに `<stack>.tfstate`）

## ローカル実行

```bash
cd stacks/20-connectivity
terraform init -reconfigure -backend-config=envs/dev/backend.hcl
terraform plan -var-file=envs/dev/terraform.tfvars
```

`-reconfigure` は必須です。環境を切り替えるたびに再実行してください
（付け忘れると別環境の State を引き継いでしまいます）。

## State バックエンドと Network Security Perimeter (NSP)

本テナントではポリシーによりストレージアカウントの `publicNetworkAccess` が
強制的に `Disabled` にされます。以下が実機検証で確認できた挙動です。

- コンテナーは**データプレーンでは作成できない**。ARM コントロールプレーン
  (`az resource create --id .../blobServices/default/containers/tfstate`) で作成する。
- NSP の **Learning モードでは到達できない**。`publicNetworkAccess = Disabled` が優先される。
- NSP を **Enforced モード**で関連付け、Inbound アクセスルールに送信元グローバル IP を
  登録すると、`publicNetworkAccess = Disabled` のままデータプレーンへ到達できる。
- ルールの反映には 60〜90 秒程度かかる。

構築手順は [`bootstrap/state-backend.sh`](bootstrap/state-backend.sh) に集約しています。

### GitHub-hosted runner からの到達

GitHub-hosted runner は送信元 IP が動的なため、NSP の IP 許可リストに固定登録できません。
そのため CI/CD では実行のたびに composite action
[`.github/actions/nsp-runner-access`](.github/actions/nsp-runner-access/action.yml) が
自身の送信元 IP を Inbound アクセスルールへ登録し、**終了時（失敗時も）必ず削除**します。

この方式には、実行 SP に NSP アクセスルールの書き込み権限が必要というトレードオフがあります。
カスタムロール `NSP Access Rule Operator`
（`networkSecurityPerimeters/profiles/accessRules/{read,write,delete}` のみ）を
NSP のリソースグループスコープで付与し、権限を最小化しています。

恒久的には **self-hosted runner** もしくは **Azure Private Networking 対応の
larger runner** へ移行し、リポジトリ変数 `NSP_NAME` を未設定にして
この一時登録処理を無効化するのが望ましい構成です。

## GitHub 側の設定

### 認証（シークレットレス）

クライアントシークレットは保持しません。Entra ID アプリの
フェデレーション資格情報 + GitHub OIDC で認証します。

- plan 用と apply 用で **別の Entra アプリ**を使い、権限を分離する
  - plan  : サブスクリプション `Reader` + State SA `Storage Blob Data Contributor`
  - apply : サブスクリプション `Contributor` + State SA `Storage Blob Data Contributor`
- フェデレーション資格情報の subject は
  `repo:<OWNER>/<REPO>:environment:<Environment 名>`

### Environments

`deployments.yml` の各エントリに対し 2 つの Environment を作成します。

| 用途 | Environment 名 | 承認ゲート |
|---|---|---|
| plan (CI) | `<env>-<stack>-plan` | なし |
| apply (CD) | `<env>-<stack>` | prd は必須 |

plan 用を分けているのは、同一 Environment にすると PR の plan 時点で
本番の承認ゲートが発火してしまうためです。

### 変数（Variables / シークレットではない）

| 変数名 | スコープ | 説明 |
|---|---|---|
| `ARM_CLIENT_ID` | Environment | plan 用 / apply 用アプリの appId |
| `ARM_TENANT_ID` | Repository | テナント ID |
| `RUNNER_LABEL` | **Repository** | 未設定なら `ubuntu-latest`。Environment に置くと `runs-on` の評価時に解決されず黙って既定へ落ちる |
| `USE_REMOTE_STATE` | Repository | `"true"` で CI もリモート State を使う。未設定ならローカル State で plan |
| `NSP_NAME` | Repository | 未設定なら NSP 一時登録処理を無効化 |
| `NSP_RESOURCE_GROUP` | Repository | NSP のリソースグループ |
| `NSP_PROFILE_NAME` | Repository | NSP プロファイル名 |
| `STATE_STORAGE_ACCOUNT` | Repository | 疎通確認に使う State ストレージアカウント名 |

### 一括セットアップ

上記の Environment と変数は [`bootstrap/github-setup.ps1`](bootstrap/github-setup.ps1) で一括作成できます。

```powershell
winget install --id GitHub.cli -e
gh auth login          # Scopes: repo, workflow

./bootstrap/github-setup.ps1 `
  -Repo             <OWNER>/<REPO> `
  -TenantId         <テナント ID> `
  -PlanClientId     <plan 用アプリの appId> `
  -ApplyClientId    <apply 用アプリの appId> `
  -NspResourceGroup <NSP のリソースグループ> `
  -NspName          <NSP 名> `
  -NspProfileName   <NSP プロファイル名> `
  -StateStorageAccount <State ストレージアカウント名>
```

prd の承認ゲート（Required reviewers）とブランチ保護は、
運用主体を明示する必要があるため手動で設定します。

## ブランチ戦略

GitHub Flow。`main` は常にリリース可能な状態に保ち、変更は短命の feature ブランチと
Pull Request を経て反映します。PR では fmt / validate / plan を実行し、
plan 結果を PR コメントで確認したうえでマージします。
