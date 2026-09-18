###############################################################################
# 20-connectivity スタック / prd（本番）
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/prd/backend.hcl
#   terraform plan  -var-file=envs/prd/terraform.tfvars -out=tfplan
#
# 本ファイルの差分 = 本番への影響。
# CODEOWNERS により上位承認者のレビューを必須としている。
###############################################################################
subscription_id = "<prd Connectivity サブスクリプション ID>"
environment     = "prd"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

# 40-management/prd の output log_analytics_workspace_id を転記する。
log_analytics_workspace_id = null

hub_vnet_address_space = ["10.0.0.0/22"]

subnet_address_prefixes = {
  GatewaySubnet        = "10.0.0.0/27"
  AzureFirewallSubnet  = "10.0.0.64/26"
  AzureBastionSubnet   = "10.0.0.128/26"
  dnsresolver_inbound  = "10.0.1.0/28"
  dnsresolver_outbound = "10.0.1.16/28"
}

###############################################################################
# Feature flags
#
# 現在は CI/CD 検証フェーズのため、課金が発生するリソースはすべて false。
# 本番構築時は段階的に true へ切り替える。
###############################################################################
deploy_firewall             = false
deploy_bastion              = false
deploy_route_table          = false
deploy_ddos_protection_plan = false

# prd のみ Premium（IDPS / TLS 検査）。
firewall_sku_tier     = "Premium"
firewall_zones        = ["1", "2", "3"]
firewall_policy_rules = []

bastion_sku   = "Standard"
bastion_zones = []

tags = {
  CostCenter  = "ccoe"
  Criticality = "high"
}
