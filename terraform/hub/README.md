# Azure Hub (Platform / Connectivity) — Terraform

ALZ 準拠 Hub-Spoke トポロジの **Hub サブスクリプション**リソースを Terraform + **Azure Verified Modules (AVM)** でデプロイします。
設計背景は `../../Azure基盤_IaC設計パラメータ.md` / `../../Azure基盤_IaC設計区分ガイド.md` を参照してください。

## デプロイされるリソース（構成図準拠）

| リソース | 実装 | 備考 |
|----------|------|------|
| Resource Group | AVM `avm-res-resources-resourcegroup` | `rg-masuda-hub-prod-jpe-001` |
| Hub VNet + Subnets | AVM `avm-res-network-virtualnetwork` | Gateway/Firewall/Bastion/DNS Resolver 用サブネット |
| Azure Firewall + Policy | AVM `avm-res-network-azurefirewall` / `-firewallpolicy` | SKU 可変（Basic/Standard/Premium） |
| Azure Bastion | AVM `avm-res-network-bastionhost` | Standard SKU |
| Public IP (Firewall/Bastion) | AVM `avm-res-network-publicipaddress` | Static |
| Route Table (Spoke egress) | AVM `avm-res-network-routetable` | `0.0.0.0/0 → Firewall Private IP` |
| Private DNS Zones + VNet Link | AVM `avm-res-network-privatednszone` + 標準 link | PaaS Private Endpoint 用 |
| DNS Private Resolver | AVM `avm-res-network-dnsresolver` | inbound / outbound endpoint |
| Log Analytics Workspace | AVM `avm-res-operationalinsights-workspace` | 集中ログ |
| Key Vault | AVM `avm-res-keyvault-vault` | Hub 共有シークレット |
| DDoS Protection Plan | AVM `avm-res-network-ddosprotectionplan` | 既定 OFF（コスト大） |
| ExpressRoute / VPN Gateway | 標準 `azurerm_virtual_network_gateway` | AVM モジュール未提供のため標準リソース。既定 ON |

> **ExpressRoute Gateway** のみ AVM リソースモジュールが未提供のため、標準 `azurerm` リソースで実装しています。他はすべて AVM を利用し作成/運用コストを最小化しています。

## 前提条件
- Terraform >= 1.10（AVM モジュールのクロス変数バリデーションに必要）
- Azure CLI (`az login`) もしくは GitHub Actions OIDC
- Connectivity サブスクリプションへの Contributor 相当権限

## デプロイ手順
```bash
cd terraform/hub
cp terraform.tfvars.example terraform.tfvars   # 値を編集
terraform init
terraform plan  -out tfplan
terraform apply tfplan
```

### リモート State（必須・CI/CD）
本番運用・CI/CD では `providers.tf` の `backend "azurerm"` を使用します。State 用ストレージは以下の手順でブートストラップしてください。

```bash
terraform init \
  -backend-config="resource_group_name=<rg>" \
  -backend-config="storage_account_name=<sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=hub/connectivity.tfstate"
```

> **重要（本テナントのポリシー制約）**
> - ストレージアカウントは **Azure Policy によりパブリックネットワークアクセスが強制的に無効化** されます。State 用ストレージには **Private Endpoint** を構成し、実行環境（**self-hosted runner を Hub VNet 内に配置**）から Private DNS 経由で解決させてください。
> - **共有キー認証も無効**のため、backend は `use_azuread_auth = true`（Entra ID 認証）を使用します。実行 ID に State ストレージへの `Storage Blob Data Contributor` を付与してください。

### ローカル検証（State ストレージ未整備時）
Private Endpoint 未整備の段階では、`backend "azurerm"` ブロックを一時的にコメントアウトするか `-backend=false` で `validate` / `plan` を実行できます（apply はローカル State を使う一時作業ディレクトリで実施）。

## CI/CD（GitHub Actions）
- `.github/workflows/ci.yml` … PR で `fmt -check` → `init` → `validate` → `plan`（成果物 `tfplan.bin` を artifact 化）
- `.github/workflows/cd.yml` … `main` push もしくは手動実行で `apply`（GitHub Environment `production` の承認ゲート付き）
- **Enterprise ポリシーで GitHub-hosted runner が無効**のため、両ワークフローとも `runs-on: [self-hosted]`。
- 認証は **OIDC**（`azure/login@v2`）。必要な Secrets：`AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` / `TFSTATE_RG` / `TFSTATE_SA` / `TFSTATE_CONTAINER`。

## 命名・タグ
- 命名：CAF 準拠 `<type>-masuda-hub-<env>-<region>-<instance>`（`org=masuda` 確定）
- 必須タグ：`Environment` / `Owner` / `CostCenter` / `Workload` / `ManagedBy=Terraform`

## Terraform 設定ポリシー（パラメータ定義方針）

本構成は **「値」と「ロジック」を分離** し、環境固有の値は `terraform.tfvars` に集約します。リソース定義（`*.tf`）に値を直書きしないことを原則とします。

### ファイル構成と役割

| ファイル | 役割 | ここに書くもの / 書かないもの |
|----------|------|--------------------------------|
| `variables.tf` | 入力変数の**宣言**（型・既定値・説明・`validation`） | 「どんなパラメータを受け付けるか」を定義。環境固有の実値は原則書かない（全環境共通の安全な既定値のみ `default` に置く） |
| `terraform.tfvars` | 環境ごとの**実パラメータ値** | `subscription_id` / CIDR / SKU / フラグ等の実値。`terraform.tfvars.example` をコピーして作成 |
| `locals.tf` | 計算値・派生値 | 命名規約の組み立て、タグ合成、subnet マップ等の固定ロジック。通常ユーザーは編集しない |
| `main.tf` / `network.tf` | リソース定義（AVM モジュール呼び出し） | `var.xxx` を参照するのみ。値そのものは持たない |
| `outputs.tf` | 出力値 | `firewall_private_ip` 等、Spoke や他スタックへ渡す値 |
| `providers.tf` | provider / backend 設定 | azurerm バージョン制約・リモート State 設定 |

### パラメータを定義する場所（優先順位）

1. **`terraform.tfvars`（第一選択）** — 環境固有の値はすべてここに集約する。
   ```hcl
   subscription_id   = "0a33aa1b-..."
   firewall_sku_tier = "Standard"
   bastion_zones     = []   # japaneast は Bastion の AZ 非対応のため空
   ```
2. **`variables.tf` の `default`** — 全環境で共通の安全側デフォルトのみ。
   ```hcl
   variable "bastion_zones" {
     type    = list(string)
     default = []   # 非対応リージョン向けの安全側デフォルト
   }
   ```
3. **CLI 引数（一時的な上書き）** — `-var-file=prod.tfvars` / `-var="env=dev"`。
4. **CI/CD（GitHub Actions）** — 機密値は `.tfvars` ではなく **Secrets / OIDC**（`ARM_*` 環境変数）で注入する。

### 値の評価順（後勝ち）

```
variables.tf の default  <  terraform.tfvars  <  *.auto.tfvars  <  -var-file  <  -var / 環境変数(TF_VAR_)
```

### 運用ルール

- **環境ごとに `.tfvars` を分離**する（例：`prod.tfvars` / `dev.tfvars`）。同一の `*.tf` コードを使い回し、差分は変数値のみとする。
- **機密情報を含む `.tfvars` は Git 管理しない**（`.gitignore` で `*.tfvars` を除外済み。コミットするのは `terraform.tfvars.example` のみ）。
- **リソース定義（`*.tf`）に値を直書きしない**。必ず `var.xxx` 経由で参照する。
- **命名は `locals.tf` の CAF 規約で自動生成**する（`<type>-<org>-hub-<env>-<region>-<instance>`）。個別リソースで名前を直書きしない。
- **リージョン依存の制約はフラグ/変数で吸収**する（例：`bastion_zones=[]`、`deploy_expressroute_gateway`、`deploy_ddos_protection_plan`）。
- **AVM モジュールのバージョンは `.terraform.lock.hcl` で固定**する（0.x は破壊的変更が入り得るため）。

## Spoke との接続
Hub デプロイ後、以下の出力を Spoke 側で利用します。
- `hub_vnet_id` … VNet Peering 用
- `firewall_private_ip` … Spoke UDR の next hop
- `spoke_egress_route_table_id` … Spoke サブネットへ関連付け
- `private_dns_zone_ids` … Private Endpoint 用ゾーン

## 未確定事項（実装前に確認）
`terraform.tfvars` の以下は設計書の要確認事項（Q2/Q4/Q5/Q6/Q8）に対応します。既定値は暫定です。
- `subscription_id`（Q2）
- `hub_vnet_address_space` / `subnet_address_prefixes`（Q4：オンプレ・既存との重複回避）
- `deploy_expressroute_gateway` / `gateway_type` / `gateway_sku`（Q5：接続方式・回線）
- `firewall_sku_tier` / `deploy_ddos_protection_plan`（Q6）
- `log_analytics_retention_days`（Q8）

## 注意（AVM バージョン）
各 AVM モジュールは `>= x.y.0, < 1.0.0` で最新の 0.x を取得します。AVM は 1.0 未満で破壊的変更が入り得るため、`terraform init` 後に `.terraform.lock.hcl` を用いてバージョンを固定してください。
