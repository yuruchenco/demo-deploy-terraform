###############################################################################
# 21-dns スタック / dev
#
# hub_virtual_network_id は 20-connectivity の output hub_vnet_id を転記する。
# terraform_remote_state で暗黙参照せず、tfvars で明示的に渡すことで
# 依存関係を PR の差分として可視化する。
###############################################################################
subscription_id = "ed77507d-7fd3-4aed-b04c-982b8f58a381"
environment     = "dev"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

hub_virtual_network_id = "/subscriptions/ed77507d-7fd3-4aed-b04c-982b8f58a381/resourceGroups/rg-masuda-hub-dev-jpe-001/providers/Microsoft.Network/virtualNetworks/vnet-masuda-hub-dev-jpe-001"

###############################################################################
# dev は最小限のゾーンのみ（05_環境差分マトリクス #13）。
# stg / prd は全 12 ゾーンを定義する。
###############################################################################
private_dns_zones = [
  "privatelink.blob.core.windows.net",
  "privatelink.vaultcore.azure.net",
]

deploy_dns_private_resolver = false

tags = {
  CostCenter  = "ccoe"
  Criticality = "low"
}
