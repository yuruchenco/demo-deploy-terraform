###############################################################################
# platform stack / stg (検証)
# Subscription: ME-MngEnvMCAP368340-yuichimasuda-2
#
# 適用: terraform plan -var-file=envs/stg/terraform.tfvars
###############################################################################
subscription_id = "7b0d56d6-0b9c-4ec4-82bb-98232df5db5b"
env             = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

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
# 検証環境。本番へ入れる前の確認はここで行う。
# 現在は CI/CD 検証フェーズのため、課金が発生するリソースはすべて false。
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
  Criticality = "medium"
}
