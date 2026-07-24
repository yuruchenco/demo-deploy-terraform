# Azure Policy — サブスクリプション単位の組み込みポリシー割当（Terraform）

`PolicyList.csv` に列挙された **57 個の組み込みポリシー定義**を、対象サブスクリプションへ一括で割り当てる Terraform 構成です。効果（Effect）ごとに必要な設定（マネージド ID・リージョン・修復用ロール割当）を**自動的に付与**します。

## 構成

| ファイル | 役割 |
|----------|------|
| `providers.tf` | Terraform / azurerm プロバイダ、リモート State backend（Entra ID 認証） |
| `variables.tf` | 入力変数（サブスクリプション、リージョン、除外、パラメータ上書き 等） |
| `main.tf` | 57 ポリシーのマップ（GUID → 効果・表示名）、割当・修復ロールのロジック |
| `outputs.tf` | 割当 ID・件数・マネージド ID の principalId 等 |
| `terraform.tfvars.example` | 変数のサンプル |

## 効果別の扱い（自動判定）

`main.tf` の `local.policies` で各ポリシーを効果別に分類し、`azurerm_subscription_policy_assignment` を `for_each` で生成します。

| 効果 | 件数 | 追加で行うこと |
|------|------|----------------|
| `Audit` / `AuditIfNotExists` / `Deny` / `None` | 18 | 割当のみ（ID 不要） |
| `DeployIfNotExists` | 37 | **SystemAssigned マネージド ID** + `location` を付与し、各ポリシー定義が要求する `role_definition_ids` を**修復用ロールとしてサブスクリプションに自動割当** |
| `Modify` | 2 | 同上 |

> 割当対象 57 件のうち 39 件（DINE 37 + Modify 2）が ID を持ち、それらが要求するロールを展開して **43 件のロール割当**が生成されます（実測 `terraform plan` 値）。

## 前提条件

- **Terraform >= 1.10**、Azure CLI
- 対象サブスクリプションへの権限:
  - ポリシー割当のため **`Resource Policy Contributor`**（または Owner）
  - 修復用ロールを付与するため **`User Access Administrator`**（または Owner）
- リモート State は Hub と同じポリシー制約 backend を使用（共有キー無効 → `use_azuread_auth=true`）

## 使い方

```powershell
# 1) 変数ファイルを用意
Copy-Item terraform.tfvars.example terraform.tfvars   # subscription_id 等を編集

# 2) init（リモート State backend。詳細は hub/README_customer.md 参照）
terraform init `
  -backend-config="resource_group_name=<rg>" `
  -backend-config="storage_account_name=<sa>" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=policy/<subscription-id>.tfstate"

# 3) まずは report-only（enforce=false）で影響を確認
terraform plan  -var="enforce=false"
terraform apply -var="enforce=false"

# 4) コンプライアンス確認後、強制モードへ
terraform apply -var="enforce=true"
```

## サブスクリプションごとの運用

本構成は**単一サブスクリプション**を対象にします。複数サブスクリプションへ展開する場合は、サブスクリプションごとに **State の `key` を分けて** 実行してください（例: `-backend-config="key=policy/<subscription-id>.tfstate"`）。CI/CD ではマトリクスで対象サブスクリプションを回す構成が推奨です。

## 主な変数

| 変数 | 既定値 | 説明 |
|------|--------|------|
| `subscription_id` | （必須） | 割当先サブスクリプション ID |
| `assignment_location` | `japaneast` | DINE / Modify のマネージド ID 用リージョン |
| `enforce` | `true` | `true`=Default（効果を強制） / `false`=DoNotEnforce（評価のみ） |
| `excluded_policies` | `[]` | 段階導入のためにスキップする GUID の一覧 |
| `not_scopes` | `[]` | 全割当から除外するリソース ID（例: 特定 RG） |
| `allowed_locations` | `[]` | 「Allowed locations」Deny ポリシーの許可リージョン |
| `policy_parameters` | `{}` | GUID → JSON 文字列でパラメータを上書き（下記参照） |

### パラメータ上書き（任意）

管理対象の 57 ポリシーは**全パラメータにデフォルトがある**ため、パラメータ未指定でも `apply` は成功します。診断ログ系（`... to Log Analytics`）ポリシーの修復先ワークスペースを明示したい場合などにのみ、`policy_parameters` で上書きします。

```hcl
policy_parameters = {
  "2465583e-4e78-4c15-b6be-a36cbc7c8b0f" = jsonencode({
    logAnalytics = { value = "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<law>" }
  })
}
```

## 段階導入の推奨手順

1. `enforce=false` で全ポリシーを割当 → コンプライアンス状態を数日観測
2. Deny（`Allowed locations`）や副作用の大きい DINE を `excluded_policies` で一時除外
3. 影響を確認しながら除外を外し、最終的に `enforce=true` へ

## リストの更新

`PolicyList.csv`（Hub フォルダ）を更新した場合は、`main.tf` の `local.policies` マップを同期してください（GUID・効果・表示名）。効果は `az policy definition show --name <guid>` の `parameters.effect.defaultValue` で確認できます。
