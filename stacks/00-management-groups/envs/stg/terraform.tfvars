###############################################################################
# 00-management-groups スタック / stg（検証）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
#   terraform plan  -var-file=envs/stg/terraform.tfvars -out=tfplan
#   terraform apply tfplan
#
# 02_スタック構成 #1 のとおり dev は存在しない。
###############################################################################
subscription_id = "<stg の任意のサブスクリプション ID（プロバイダー認証用）>"
environment     = "stg"
org             = "masuda"

###############################################################################
# Feature flags
#
# 【重要】有効化には tenant root スコープの Management Group Contributor
# （または Owner）が必要。未付与のまま apply すると AuthorizationFailed となる。
###############################################################################
deploy_management_groups = false

intermediate_root_display_name = "Platform Root (stg)"

###############################################################################
# 階層定義（ALZ 標準階層）
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
# 移動は Policy の適用範囲を変える操作のため、既定では空にしておく。
# 移動対象が確定した時点で 1 件ずつ追記し、PR の plan 差分でレビューする。
###############################################################################
subscription_associations = {}
