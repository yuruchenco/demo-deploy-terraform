###############################################################################
# 21-dns スタック / stg（検証）
#
# hub_virtual_network_id は 20-connectivity/stg の output hub_vnet_id を転記する。
###############################################################################
subscription_id = "<stg Connectivity サブスクリプション ID>"
environment     = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

hub_virtual_network_id = "<20-connectivity/stg の hub_vnet_id>"

# stg / prod は全 12 ゾーンを定義する（05_環境差分マトリクス #13）。
private_dns_zones = [
  "privatelink.blob.core.windows.net",
  "privatelink.file.core.windows.net",
  "privatelink.queue.core.windows.net",
  "privatelink.table.core.windows.net",
  "privatelink.dfs.core.windows.net",
  "privatelink.vaultcore.azure.net",
  "privatelink.database.windows.net",
  "privatelink.documents.azure.com",
  "privatelink.azurecr.io",
  "privatelink.azurewebsites.net",
  "privatelink.monitor.azure.com",
  "privatelink.servicebus.windows.net",
]

deploy_dns_private_resolver = false

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
