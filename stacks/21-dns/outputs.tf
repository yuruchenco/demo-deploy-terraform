output "resource_group_name" {
  description = "Name of the DNS resource group."
  value       = module.rg.name
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone name -> resource ID. 1 件も作成しない場合は空マップ。"
  value       = { for k, v in module.private_dns_zones : k => v.resource_id }
}

output "dns_private_resolver_id" {
  description = "Resource ID of the DNS Private Resolver (null if not deployed)."
  value       = one(module.dns_private_resolver[*].resource_id)
}

output "dns_private_resolver_inbound_ip" {
  description = "Inbound endpoint private IP of the DNS Private Resolver (null if not deployed). Hub VNet の DNS サーバー設定に使う。"
  value       = one(module.dns_private_resolver[*].inbound_endpoints["inbound"].ip_configurations[0].private_ip_address)
}
