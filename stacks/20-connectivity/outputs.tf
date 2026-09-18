###############################################################################
# Resource Group
###############################################################################
output "resource_group_name" {
  description = "Name of the Hub resource group. 22-gateway の tfvars に転記する。"
  value       = module.rg.name
}

output "resource_group_id" {
  description = "Resource ID of the Hub resource group."
  value       = module.rg.resource_id
}

###############################################################################
# Networking
###############################################################################
output "hub_vnet_id" {
  description = "Resource ID of the Hub VNet. 21-dns の hub_virtual_network_id とスポーク側のピアリングに使う。"
  value       = module.hub_vnet.resource_id
}

output "hub_vnet_name" {
  description = "Name of the Hub VNet."
  value       = module.hub_vnet.name
}

output "hub_subnet_ids" {
  description = "Map of Hub subnet name -> resource ID. GatewaySubnet の値を 22-gateway の tfvars に転記する。"
  value       = { for k, v in module.hub_vnet.subnets : k => v.resource_id }
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall (null if not deployed)."
  value       = one(module.firewall[*].resource_id)
}

output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall (null if not deployed). スポークの UDR の next hop に使う。"
  value       = one(module.firewall[*].resource.ip_configuration[0].private_ip_address)
}

output "spoke_egress_route_table_id" {
  description = "Resource ID of the spoke egress route table (null if not deployed)."
  value       = one(module.route_table_spoke[*].resource_id)
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host (null if not deployed)."
  value       = one(module.bastion[*].resource_id)
}

output "ddos_protection_plan_id" {
  description = "Resource ID of the DDoS protection plan (null if not deployed)."
  value       = one(module.ddos[*].resource_id)
}
