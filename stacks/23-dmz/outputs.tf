output "dmz_vnet_id" {
  description = "Resource ID of the DMZ VNet."
  value       = module.dmz_vnet.resource_id
}

output "app_gateway_id" {
  description = "Resource ID of the Application Gateway (null if not deployed)."
  value       = one(azurerm_application_gateway.this[*].id)
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway (null if not deployed)."
  value       = one(azurerm_public_ip.appgw[*].ip_address)
}
