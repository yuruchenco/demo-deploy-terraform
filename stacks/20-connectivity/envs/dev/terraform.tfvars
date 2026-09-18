###############################################################################
# 20-connectivity スタック / dev
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/dev/backend.hcl
#   terraform plan  -var-file=envs/dev/terraform.tfvars -out=tfplan
#   terraform apply tfplan
###############################################################################
subscription_id = "ed77507d-7fd3-4aed-b04c-982b8f58a381"
environment     = "dev"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

###############################################################################
# 40-management の output log_analytics_workspace_id を転記する。
# 未作成のうちは null のままでよい（診断設定が作られないだけ）。
###############################################################################
log_analytics_workspace_id = "/subscriptions/ed77507d-7fd3-4aed-b04c-982b8f58a381/resourceGroups/rg-masuda-mgmt-dev-jpe-001/providers/Microsoft.OperationalInsights/workspaces/log-masuda-mgmt-dev-jpe-001"

###############################################################################
# Network
###############################################################################
hub_vnet_address_space = ["10.10.0.0/22"]

subnet_address_prefixes = {
  GatewaySubnet        = "10.10.0.0/27"
  AzureFirewallSubnet  = "10.10.0.64/26"
  AzureBastionSubnet   = "10.10.0.128/26"
  dnsresolver_inbound  = "10.10.1.0/28"
  dnsresolver_outbound = "10.10.1.16/28"
}

###############################################################################
# Feature flags
#
# 設計上 dev でも Firewall / Bastion は true だが、
# 本検証は OIDC・backend・CI/CD 経路の確認が目的であり、
# 課金の大きいリソースは意図的に false のままとしている。
###############################################################################
deploy_firewall             = false
deploy_bastion              = false
deploy_route_table          = false
deploy_ddos_protection_plan = false

firewall_sku_tier     = "Basic"
firewall_zones        = []
firewall_policy_rules = []

bastion_sku   = "Basic"
bastion_zones = []

tags = {
  CostCenter  = "ccoe"
  Criticality = "low"
}
