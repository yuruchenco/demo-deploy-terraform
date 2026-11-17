###############################################################################
# 23-dmz スタック / dev
#
# 検証用の擬似構成: Hub と DMZ は本来別サブスクリプションだが、検証テナントには
# サブスクリプションが 1 つしかないため、同一サブスクリプション内の別 RG で代替する。
# DMZ 用 SP の書き込み権限は DMZ 用 RG と Hub VNet のピアリングに限定している。
###############################################################################
environment    = "dev"
org            = "masuda"
location       = "japaneast"
location_short = "jpe"
instance       = "001"

resource_group_name = "rg-masuda-dmz-dev-jpe-001"

# 20-connectivity の output hub_vnet_id を転記する。
hub_virtual_network_id = "/subscriptions/ed77507d-7fd3-4aed-b04c-982b8f58a381/resourceGroups/rg-masuda-hub-dev-jpe-001/providers/Microsoft.Network/virtualNetworks/vnet-masuda-hub-dev-jpe-001"

# 40-management の output log_analytics_workspace_id を転記する。
log_analytics_workspace_id = "/subscriptions/ed77507d-7fd3-4aed-b04c-982b8f58a381/resourceGroups/rg-masuda-mgmt-dev-jpe-001/providers/Microsoft.OperationalInsights/workspaces/log-masuda-mgmt-dev-jpe-001"

dmz_vnet_address_space      = ["10.11.0.0/24"]
appgw_subnet_address_prefix = "10.11.0.0/26"

# 検証のため一時的に作成する（確認後 false に戻して削除する）。
deploy_app_gateway   = false
app_gateway_capacity = 1
app_gateway_zones    = []

tags = {
  CostCenter  = "ccoe"
  Criticality = "low"
}
