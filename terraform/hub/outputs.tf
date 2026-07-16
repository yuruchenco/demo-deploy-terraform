###############################################################################
# Resource Group
###############################################################################
output "resource_group_name" {
  description = "Name of the Hub resource group."
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
  description = "Resource ID of the Hub VNet. Use for spoke peering."
  value       = module.hub_vnet.resource_id
}

output "hub_vnet_name" {
  description = "Name of the Hub VNet."
  value       = module.hub_vnet.name
}

output "hub_subnet_ids" {
  description = "Map of Hub subnet name -> resource ID."
  value       = { for k, v in module.hub_vnet.subnets : k => v.resource_id }
}

output "firewall_id" {
  description = "Resource ID of the Azure Firewall."
  value       = module.firewall.resource_id
}

output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall. Use as next hop in spoke UDRs."
  value       = module.firewall.resource.ip_configuration[0].private_ip_address
}

output "spoke_egress_route_table_id" {
  description = "Resource ID of the spoke egress route table (0.0.0.0/0 -> Firewall). Associate to spoke subnets."
  value       = module.route_table_spoke.resource_id
}

output "bastion_id" {
  description = "Resource ID of the Azure Bastion host."
  value       = module.bastion.resource_id
}

output "expressroute_gateway_id" {
  description = "Resource ID of the ExpressRoute/VPN Gateway (null if not deployed)."
  value       = try(azurerm_virtual_network_gateway.this[0].id, null)
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone name -> resource ID."
  value       = { for k, v in module.private_dns_zones : k => v.resource_id }
}

output "dns_private_resolver_id" {
  description = "Resource ID of the DNS Private Resolver (null if not deployed)."
  value       = try(module.dns_private_resolver[0].resource_id, null)
}

###############################################################################
# Shared platform services
###############################################################################
output "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  value       = module.law.resource_id
}

output "key_vault_id" {
  description = "Resource ID of the Hub Key Vault."
  value       = module.key_vault.resource_id
}

output "ddos_protection_plan_id" {
  description = "Resource ID of the DDoS protection plan (null if not deployed)."
  value       = try(module.ddos[0].resource_id, null)
}
