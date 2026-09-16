###############################################################################
# platform stack / dev (Sandbox)
# Subscription: ME-MngEnvMCAP368340-yuichimasuda-2
#
# 本来は Sandbox テナントを使用する。本検証では同一テナント内の
# 2 つ目のサブスクリプションで代用している。
#
# 適用: terraform plan -var-file=envs/dev/terraform.tfvars
###############################################################################
subscription_id = "7b0d56d6-0b9c-4ec4-82bb-98232df5db5b"
env             = "dev"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

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
# dev で true にしたものが、勝手に stg / prd へ波及することはない。
# 昇格させたい場合は envs/stg, envs/prd の tfvars を明示的に変更し、
# PR で plan 差分をレビューすること。
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
  Criticality = "low"
}
