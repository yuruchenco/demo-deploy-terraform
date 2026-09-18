###############################################################################
# 22-gateway スタック / stg（検証）
#
# stg は VPN Gateway を使用する（05_環境差分マトリクス #15-17）。
# VPN では Public IP が必要なため deploy_gateway_public_ip = true。
###############################################################################
subscription_id = "<stg Connectivity サブスクリプション ID>"
environment     = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

resource_group_name = "<20-connectivity/stg の resource_group_name>"
gateway_subnet_id   = "<20-connectivity/stg の hub_subnet_ids.GatewaySubnet>"

gateway_type             = "None"
gateway_sku              = null
deploy_gateway_public_ip = false

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
