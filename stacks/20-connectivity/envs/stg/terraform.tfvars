###############################################################################
# 20-connectivity スタック / stg（検証）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
#   terraform plan  -var-file=envs/stg/terraform.tfvars -out=tfplan
#
# subscription_id は本番テナントの Connectivity サブスクリプションを指定する。
# 環境取り違え時の最後の砦であるため、provider に明示指定している。
###############################################################################
subscription_id = "<stg Connectivity サブスクリプション ID>"
environment     = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

# 40-management/stg の output log_analytics_workspace_id を転記する。
log_analytics_workspace_id = null

hub_vnet_address_space = ["10.20.0.0/22"]

subnet_address_prefixes = {
  GatewaySubnet        = "10.20.0.0/27"
  AzureFirewallSubnet  = "10.20.0.64/26"
  AzureBastionSubnet   = "10.20.0.128/26"
  dnsresolver_inbound  = "10.20.1.0/28"
  dnsresolver_outbound = "10.20.1.16/28"
}

###############################################################################
# Feature flags
#
# 現在は CI/CD 検証フェーズのため、課金が発生するリソースはすべて false。
# 有効化する際は必ず PR 上で plan 差分をレビューすること。
###############################################################################
deploy_firewall             = false
deploy_bastion              = false
deploy_route_table          = false
deploy_ddos_protection_plan = false

firewall_sku_tier     = "Standard"
firewall_zones        = ["1", "2", "3"]
firewall_policy_rules = []

bastion_sku   = "Basic"
bastion_zones = []

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
