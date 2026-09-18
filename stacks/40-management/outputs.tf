output "resource_group_name" {
  description = "Name of the management resource group."
  value       = module.rg.name
}

output "resource_group_id" {
  description = "Resource ID of the management resource group."
  value       = module.rg.resource_id
}

output "log_analytics_workspace_id" {
  description = <<-EOT
    Resource ID of the central Log Analytics workspace (null if not deployed).

    この値は 20-connectivity / 10-policy の
    envs/<env>/terraform.tfvars へ手動で転記する運用とする。
    null のまま下流へ伝播させないこと。
  EOT
  value       = one(module.law[*].resource_id)
}

output "key_vault_id" {
  description = "Resource ID of the platform Key Vault (null if not deployed)."
  value       = one(module.key_vault[*].resource_id)
}

output "key_vault_uri" {
  description = "URI of the platform Key Vault (null if not deployed)."
  value       = one(module.key_vault[*].uri)
}
