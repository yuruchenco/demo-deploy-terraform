###############################################################################
# 30-identity スタック / prd（本番）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/prd/backend.hcl
#   terraform plan  -var-file=envs/prd/terraform.tfvars -out=tfplan
#   terraform apply tfplan
#
# 02_スタック構成 #6 のとおり dev は存在しない。
# 本ファイルの差分は権限そのものの変更となるため、
# CODEOWNERS により上位承認を要求する。
###############################################################################
subscription_id = "<prd Identity サブスクリプション ID>"
environment     = "prd"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

###############################################################################
# 上流スタックからの受け渡し
#
# 00-management-groups の output `level1_management_group_ids["platform"]` を転記する。
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
#
# stg と同一構成とし、「stg で検証した ID をそのまま昇格する」ことを担保する。
###############################################################################
user_assigned_identities = {
  policy-remediation = { purpose = "Azure Policy DeployIfNotExists remediation" }
}

###############################################################################
# カスタムロール定義
#
# ロール名はテナント内で一意である必要があるため、環境サフィックスを付ける。
###############################################################################
custom_role_definitions = {
  "NSP Access Rule Operator" = {
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
# 【注意】ここからエントリを削除すると、該当の権限が即座に剥奪される。
# CI/CD 実行 SP 自身の権限を含める場合は、自分自身を締め出さないよう
# 変更前に必ず plan 差分を確認すること。
###############################################################################
role_assignments = {}

tags = {
  CostCenter  = "ccoe"
  Criticality = "high"
}
