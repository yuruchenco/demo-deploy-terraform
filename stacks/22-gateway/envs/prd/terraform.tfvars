###############################################################################
# 22-gateway スタック / prd（本番）
#
# prd は ExpressRoute Gateway を使用する（05_環境差分マトリクス #15-17）。
# ExpressRoute では Public IP を指定するとエラーになるため
# deploy_gateway_public_ip = false のままとする（variables.tf で検証済み）。
#
# Gateway は作成に 30-45 分かかる。
###############################################################################
subscription_id = "<prd Connectivity サブスクリプション ID>"
environment     = "prd"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

resource_group_name = "<20-connectivity/prd の resource_group_name>"
gateway_subnet_id   = "<20-connectivity/prd の hub_subnet_ids.GatewaySubnet>"

gateway_type             = "None"
gateway_sku              = null
deploy_gateway_public_ip = false

tags = {
  CostCenter  = "ccoe"
  Criticality = "high"
}
