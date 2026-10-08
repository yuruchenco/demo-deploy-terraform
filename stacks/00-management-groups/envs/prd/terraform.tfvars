###############################################################################
# 00-management-groups スタック / prd（本番）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/prd/backend.hcl
#   terraform plan  -var-file=envs/prd/terraform.tfvars -out=tfplan
#   terraform apply tfplan
#
# 02_スタック構成 #1 のとおり dev は存在しない。
# 本ファイルの差分は全社（テナント）影響となるため、
# CODEOWNERS により上位承認を要求する。
###############################################################################
subscription_id = "<prd の任意のサブスクリプション ID（プロバイダー認証用）>"
environment     = "prd"
org             = "masuda"

###############################################################################
# Feature flags
#
# 【重要】有効化には tenant root スコープの Management Group Contributor
# （または Owner）が必要。未付与のまま apply すると AuthorizationFailed となる。
###############################################################################
deploy_management_groups = false

intermediate_root_display_name = "Platform Root"

###############################################################################
# 階層定義（ALZ 標準階層）
#
# stg と同一構成とし、「stg で検証した階層をそのまま昇格する」ことを担保する。
###############################################################################
level1_management_groups = {
  platform       = { display_name = "Platform" }
  landingzones   = { display_name = "Landing Zones" }
  sandbox        = { display_name = "Sandbox" }
  decommissioned = { display_name = "Decommissioned" }
}

level2_management_groups = {
  identity     = { display_name = "Identity", parent_key = "platform" }
  management   = { display_name = "Management", parent_key = "platform" }
  connectivity = { display_name = "Connectivity", parent_key = "platform" }
  corp         = { display_name = "Corp", parent_key = "landingzones" }
  online       = { display_name = "Online", parent_key = "landingzones" }
}

###############################################################################
# サブスクリプションの関連付け
#
# 【注意】ここからエントリを削除すると、当該サブスクリプションは
# テナントルート直下へ戻り、配下の Policy 割り当てが一斉に外れる。
# 削除は destroy 相当の影響を持つ操作として扱うこと。
###############################################################################
subscription_associations = {}
