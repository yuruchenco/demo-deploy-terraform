###############################################################################
# 21-dns スタック / prod（本番）
#
# Private DNS Zone は変更頻度が低い一方、誤削除・誤リンクの影響が特大となる。
# 本ファイルの差分は必ず上位承認者がレビューすること。
###############################################################################
subscription_id = "<prod Connectivity サブスクリプション ID>"
environment     = "prod"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

hub_virtual_network_id = "<20-connectivity/prod の hub_vnet_id>"

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
  Criticality = "high"
}
