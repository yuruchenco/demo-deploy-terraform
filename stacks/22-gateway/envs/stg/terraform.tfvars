###############################################################################
# 22-gateway スタック / stg（検証）
#
# stg は VPN Gateway を使用する（05_環境差分マトリクス #15-17）。
# VPN では Public IP が必要なため deploy_gateway_public_ip = true。
###############################################################################
environment    = "stg"
org            = "masuda"
location       = "japaneast"
location_short = "jpe"
instance       = "001"

resource_group_name = "rg-masuda-hub-stg-jpe-001"
gateway_subnet_id   = "/subscriptions/ed77507d-7fd3-4aed-b04c-982b8f58a381/resourceGroups/rg-masuda-hub-stg-jpe-001/providers/Microsoft.Network/virtualNetworks/vnet-masuda-hub-stg-jpe-001/subnets/GatewaySubnet"

gateway_type             = "None"
gateway_sku              = null
deploy_gateway_public_ip = false

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
