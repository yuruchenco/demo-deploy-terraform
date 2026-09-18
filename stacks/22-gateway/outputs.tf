output "gateway_id" {
  description = "Resource ID of the Virtual Network Gateway (null if gateway_type = None)."
  value       = one(azurerm_virtual_network_gateway.this[*].id)
}

output "gateway_public_ip" {
  description = "Public IP address of the gateway (null if not deployed / ExpressRoute)."
  value       = one(azurerm_public_ip.gateway[*].ip_address)
}
