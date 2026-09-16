###############################################################################
# platform stack / prd (本番)
# Subscription: ME-MngEnvMCAP368340-yuichimasuda-1
#
# 適用: terraform plan -var-file=envs/prd/terraform.tfvars
###############################################################################
subscription_id = "0a33aa1b-d8ef-429b-926d-da98db87b7cb"
env             = "prd"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

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
# リソースグループと Hub VNet / サブネットのみが作成される。
#
# 本番構築時は以下を段階的に true へ切り替える。
# その際は必ず PR 上で plan 差分をレビューすること。
###############################################################################
deploy_log_analytics        = false
deploy_key_vault            = false
deploy_firewall             = false
deploy_bastion              = false
deploy_route_table          = false
deploy_dns_private_resolver = false
deploy_expressroute_gateway = false
deploy_ddos_protection_plan = false

private_dns_zones = []

tags = {
  CostCenter  = "ccoe"
  Criticality = "high"
}
