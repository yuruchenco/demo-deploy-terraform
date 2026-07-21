# Azure Hub (Platform / Connectivity) — Terraform 導入・運用ガイド（顧客向け）

ALZ 準拠 Hub-Spoke トポロジの **Hub サブスクリプション**リソースを Terraform + **Azure Verified Modules (AVM)** でデプロイ・運用するための手順書です。
本ガイドは、**ストレージのパブリックアクセス無効／共有キー認証無効**が Azure Policy で強制されている環境（ゼロトラスト前提）でも Terraform のリモート State を安全に扱えるよう、実際に検証した手順をまとめています。

---

## 1. デプロイされるリソース（構成図準拠）

| リソース | 実装 | 備考 |
|----------|------|------|
| Resource Group | AVM `avm-res-resources-resourcegroup` | `rg-<org>-hub-<env>-<region>-<instance>` |
| Hub VNet + Subnets | AVM `avm-res-network-virtualnetwork` | Gateway/Firewall/Bastion/DNS Resolver 用サブネット |
| Azure Firewall + Policy | AVM `avm-res-network-azurefirewall` / `-firewallpolicy` | SKU 可変（Basic/Standard/Premium） |
| Azure Bastion | AVM `avm-res-network-bastionhost` | SKU 可変。リージョンが AZ 非対応の場合は `bastion_zones=[]` |
| Public IP (Firewall/Bastion) | AVM `avm-res-network-publicipaddress` | Static |
| Route Table (Spoke egress) | AVM `avm-res-network-routetable` | `0.0.0.0/0 → Firewall Private IP` |
| Private DNS Zones + VNet Link | AVM `avm-res-network-privatednszone` | PaaS Private Endpoint 用（12 ゾーン） |
| DNS Private Resolver | AVM `avm-res-network-dnsresolver` | inbound / outbound endpoint |
| Log Analytics Workspace | AVM `avm-res-operationalinsights-workspace` | 集中ログ |
| Key Vault | AVM `avm-res-keyvault-vault` | Hub 共有シークレット |
| DDoS Protection Plan | AVM `avm-res-network-ddosprotectionplan` | 既定 OFF（コスト大） |
| ExpressRoute / VPN Gateway | 標準 `azurerm_virtual_network_gateway` | AVM 未提供のため標準リソース。`ExpressRoute` 時は Public IP 不要 |

> ExpressRoute Gateway のみ AVM リソースモジュールが未提供のため標準 `azurerm` リソースで実装しています。他はすべて AVM を利用し作成/運用コストを最小化しています。

---

## 2. 前提条件

- **Terraform >= 1.10**（AVM モジュールのクロス変数バリデーションに必要。1.6/1.9 では `init` が失敗します）
- Azure CLI
- 対象サブスクリプションへの **Contributor 相当**権限
- State 用ストレージへの **`Storage Blob Data Contributor`**（共有キー無効環境では Entra ID 認証必須のため）

---

## 3. リモート State バックエンドの準備（ポリシー制約環境）

本環境では Azure Policy により、State 用ストレージアカウントに次の制約が**強制**されます。

| 制約 | 内容 | 影響 |
|------|------|------|
| `publicNetworkAccess = Disabled` | パブリック経路を完全遮断。**IP 許可リストも無効化**される | ローカル PC から直接 Blob へアクセス不可 |
| `allowSharedKeyAccess = false` | 共有キー（アカウントキー）認証を禁止 | backend は **Entra ID 認証**（`use_azuread_auth=true`）必須 |

そのため、State へアクセスするには **Private Endpoint + プライベート接続**が必要です。以下いずれかの実行環境から操作します。

- **推奨（本番）**: self-hosted GitHub Actions runner を対象 VNet 内に配置（CI/CD）
- **手動運用/検証**: 対象 VNet 内に**踏み台 VM** を立て、Azure Bastion 経由で接続して Terraform を実行

### 3-1. State ストレージと Private Endpoint

```bash
# 1) State 用ストレージ（既存でも可。共有キー無効・public 無効が Policy で強制される）
az group create -n rg-tfstate -l japaneast
az storage account create -n <sa-name> -g rg-tfstate -l japaneast \
  --sku Standard_LRS --min-tls-version TLS1_2

# 2) VNet（既存 Hub VNet でも可）と Private Endpoint 用サブネット
#    Private Endpoint を blob サブリソースで作成
az network private-endpoint create -g rg-tfstate -n pe-<sa-name>-blob \
  --vnet-name <vnet> --subnet <pe-subnet> \
  --private-connection-resource-id <storage-account-resource-id> \
  --group-id blob --connection-name conn-blob

# 3) Private DNS ゾーンを VNet にリンクし、PE に DNS ゾーングループを設定
az network private-dns zone create -g rg-tfstate -n privatelink.blob.core.windows.net
az network private-dns link vnet create -g rg-tfstate \
  --zone-name privatelink.blob.core.windows.net -n link-<vnet> \
  --virtual-network <vnet> --registration-enabled false
az network private-endpoint dns-zone-group create -g rg-tfstate \
  --endpoint-name pe-<sa-name>-blob -n zg-blob \
  --private-dns-zone privatelink.blob.core.windows.net --zone-name blob
```

### 3-2. State コンテナの作成（重要な回避策）

> **ポイント**: `public 無効`のため、`az storage container create`（データプレーン）は**ローカルから失敗**します。
> **コンテナ作成は ARM コントロールプレーン経由**で行えば、ネットワーク制限の対象外となり作成できます。

```bash
az resource create \
  --id "<storage-account-resource-id>/blobServices/default/containers/tfstate" \
  --api-version 2023-05-01 --properties '{}'
```

> `<storage-account-resource-id>` は
> `/subscriptions/<sub>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/<sa-name>` の形式です。

### 3-3. アクセス権限（Entra ID 認証）

State を読み書きする**実行 ID**（VM のマネージド ID、self-hosted runner の ID、または個人ユーザー）に、State ストレージスコープで `Storage Blob Data Contributor` を付与します。

```bash
az role assignment create \
  --assignee-object-id <principal-id> --assignee-principal-type <User|ServicePrincipal> \
  --role "Storage Blob Data Contributor" \
  --scope "<storage-account-resource-id>"
```

---

## 4. 踏み台 VM からの手動デプロイ手順（検証・運用）

パブリックアクセスが遮断されているため、**VNet 内の踏み台 VM 上で Terraform を実行**します。ローカル PC は Bastion 経由の操作端末として使います。

### 4-1. 踏み台環境（一度だけ構築）

- 対象 VNet に `AzureBastionSubnet`（/26 以上）を用意
- **Azure Bastion**（Basic 以上）+ Public IP を作成
- **Windows VM**（例: Standard_B2s / Windows Server 2022）を作成し、**システム割り当てマネージド ID を有効化**
- VM のマネージド ID に権限付与:
  - State ストレージへ `Storage Blob Data Contributor`
  - Hub をデプロイする対象サブスクリプションへ `Contributor`

> **VM CLI 拡張の注意**: 一部環境で `az network bastion create` が CLI 拡張の読込エラーになる場合があります。その際は **ARM テンプレート/`az deployment group create`** で `Microsoft.Network/bastionHosts` を直接デプロイすれば回避できます。

### 4-2. 踏み台 VM 上でのツール導入

新規 Windows VM には git / terraform が入っていないため導入します（VM 上の PowerShell で実行）。

```powershell
# Terraform 1.13.x
$d="C:\tools\terraform"; New-Item -ItemType Directory -Force $d | Out-Null
Invoke-WebRequest "https://releases.hashicorp.com/terraform/1.13.3/terraform_1.13.3_windows_amd64.zip" -OutFile "$d\tf.zip"
Expand-Archive "$d\tf.zip" $d -Force; Remove-Item "$d\tf.zip"

# Git for Windows（サイレント）
$g="$env:TEMP\git.exe"
Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe" -OutFile $g
Start-Process $g -ArgumentList "/VERYSILENT","/NORESTART","/SP-" -Wait

# マシン PATH に追加
$p=[Environment]::GetEnvironmentVariable("Path","Machine")
foreach($x in @("C:\tools\terraform","C:\Program Files\Git\cmd")){ if($p -notlike "*$x*"){ $p="$x;$p" } }
[Environment]::SetEnvironmentVariable("Path",$p,"Machine")
```

> **PATH 反映**: インストール後、**既存の PowerShell セッションには PATH が反映されません**。新しいセッションを開くか、次の 1 行で即時反映します。
> ```powershell
> $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
> ```

### 4-3. Terraform ファイルの取得

- **GitHub 経由**: `git clone https://github.com/<org>/<repo>.git`
  - プライベートリポジトリで、VM でパスキー/Authenticator が使えない場合は、**ローカル PC で作成した PAT（Personal Access Token, `repo` スコープ）** を使うと確実です:
    `git clone https://<PAT>@github.com/<org>/<repo>.git`
- **GitHub を使わない場合**: `terraform/hub` 配下一式を VM の作業フォルダ（例 `C:\tf\hub`）へコピー

### 4-4. init / plan / apply（マネージド ID 認証）

```powershell
cd C:\tf\hub

# マネージド ID で認証（az login も共有キーも不要）
$env:ARM_USE_MSI="true"
$env:ARM_SUBSCRIPTION_ID="<subscription-id>"
$env:ARM_TENANT_ID="<tenant-id>"

terraform init `
  -backend-config="resource_group_name=rg-tfstate" `
  -backend-config="storage_account_name=<sa-name>" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=hub/connectivity.tfstate"

# Private Endpoint 経由の名前解決確認（privateIP が返れば OK）
nslookup <sa-name>.blob.core.windows.net

Copy-Item terraform.tfvars.example terraform.tfvars   # 値を編集
terraform plan  -out tfplan
terraform apply tfplan
```

> backend は `providers.tf` で `use_azuread_auth=true` を設定済みです。マネージド ID を使う場合は上記 `ARM_USE_MSI=true` で認証されます（安定させたい場合は backend ブロックに `use_msi = true` を明示追記）。

---

## 5. トラブルシューティング（本環境で実際に遭遇した事象）

| 症状 | 原因 | 対処 |
|------|------|------|
| `Unsupported Terraform Core version ... 1.6.3` | Terraform が古い | **1.10 以上**へ更新（AVM は 1.9+ 要求） |
| `git`/`terraform` が not recognized | インストール済みだが**セッションの PATH 未反映** | 新しい PowerShell を開く、または §4-2 の PATH 即時反映 1 行を実行 |
| GitHub 認証がパスキー/Authenticator で通らない | VM で MFA デバイスが使えない | ローカル PC で **PAT** を発行し `https://<PAT>@github.com/...` で clone、または §4-3 のファイルコピー |
| `init` で `ContainerNotFound (404)` | State コンテナ未作成（**認証・接続は成功**している） | §3-2 の **ARM 経由でコンテナ作成** |
| `az storage container create` がローカルから失敗 | `public 無効`でデータプレーン遮断 | コンテナ作成は **ARM コントロールプレーン**（§3-2）で行う |
| `public IP address cannot be set when type is ExpressRoute` | ER Gateway に Public IP を指定 | ER 時は Public IP 不要（VPN 時のみ）。本コードは修正済み |
| `BastionRegionAzNotSupported` | リージョンが Bastion の AZ 非対応（例: japaneast） | `bastion_zones = []` を指定（本コードは変数で制御） |

---

## 6. パラメータ定義方針（設定ポリシー）

- 環境固有の値は **`terraform.tfvars` に集約**し、`*.tf` にハードコードしない
- `variables.tf` の `default` は**全環境共通の安全側デフォルト**のみ
- 値の評価順（後勝ち）: `default` < `terraform.tfvars` < `*.auto.tfvars` < `-var-file` < `-var` / `TF_VAR_`
- **機密値を含む `.tfvars` は Git 管理しない**（`.gitignore` で `*.tfvars` 除外。コミットは `*.example` のみ）
- 環境ごとに `.tfvars` を分離（`prod.tfvars` / `dev.tfvars`）し、同一コードを使い回す
- AVM のバージョンは `.terraform.lock.hcl` で固定（0.x は破壊的変更が入り得るため）

主なパラメータは `terraform.tfvars.example` を参照してください（subscription_id / CIDR / SKU / Gateway 種別 / 各種デプロイフラグ）。

---

## 7. コスト注意・撤去

Hub には課金の大きいリソースが含まれます。検証後は不要なものを削除してください。

- **ExpressRoute Gateway**（`ErGw1AZ`）: プロビジョニングに 30〜45 分。常時課金
- **Azure Firewall** / **Bastion**: 常時課金
- **DDoS Protection Plan**: 既定 OFF（有効化すると高額）

```powershell
# Hub リソースの撤去
terraform destroy -var-file=terraform.tfvars

# 踏み台 VM の停止（課金停止）
az vm deallocate -g <rg> -n <vm>
```

---

## 8. Spoke との接続

Hub デプロイ後、以下の出力（`terraform output`）を Spoke 側で利用します。

- `hub_vnet_id` … VNet Peering 用
- `firewall_private_ip` … Spoke UDR の next hop
- `spoke_egress_route_table_id` … Spoke サブネットへ関連付け
- `private_dns_zone_ids` … Private Endpoint 用ゾーン
