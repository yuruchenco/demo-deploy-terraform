###############################################################################
# 30-identity スタック / stg（検証）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
#   terraform plan  -var-file=envs/stg/terraform.tfvars -out=tfplan
#   terraform apply tfplan
#
# 02_スタック構成 #6 のとおり dev は存在しない。
###############################################################################
subscription_id = "<stg Identity サブスクリプション ID>"
environment     = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

###############################################################################
# 上流スタックからの受け渡し
#
# 00-management-groups の output `level1_management_group_ids["platform"]` を転記する。
# null のままならサブスクリプションスコープへフォールバックする。
###############################################################################
platform_management_group_id = null

###############################################################################
# Feature flags
###############################################################################
deploy_resource_group           = false
deploy_user_assigned_identities = false
deploy_custom_role_definitions  = false
deploy_role_assignments         = false

###############################################################################
# ユーザー割り当てマネージド ID
###############################################################################
user_assigned_identities = {
  policy-remediation = { purpose = "Azure Policy DeployIfNotExists remediation" }
}

###############################################################################
# カスタムロール定義
#
# NSP Access Rule Operator は、CI の runner IP を NSP の Inbound アクセスルールへ
# 一時登録／削除するためだけの最小権限ロール（README「State バックエンドと NSP」参照）。
# Network Contributor を丸ごと与えずに済ませるために定義する。
###############################################################################
custom_role_definitions = {
  "NSP Access Rule Operator (stg)" = {
    description = "NSP のアクセスルールのみを操作できる最小権限ロール。CI の runner IP 一時登録に使用する。"
    actions = [
      "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/read",
      "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/write",
      "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/delete",
    ]
  }
}

###############################################################################
# ロール割り当て
#
# principal_id は Entra ID のオブジェクト ID。
# 対象が確定した時点で 1 件ずつ追記し、PR の plan 差分でレビューする。
###############################################################################
role_assignments = {}

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
