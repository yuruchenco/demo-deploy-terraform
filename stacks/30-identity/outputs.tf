output "resource_group_name" {
  description = "Name of the identity resource group (null if not deployed)."
  value       = local.resource_group_name
}

output "resource_group_id" {
  description = "Resource ID of the identity resource group (null if not deployed)."
  value       = one(module.rg[*].resource_id)
}

output "user_assigned_identity_ids" {
  description = "ユーザー割り当てマネージド ID の resource ID（キー => ID）。"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.id }
}

output "user_assigned_identity_principal_ids" {
  description = <<-EOT
    ユーザー割り当てマネージド ID の principal ID（キー => ID）。

    10-policy の DeployIfNotExists 修復用 ID として、
    下流スタックの envs/<env>/terraform.tfvars へ手動で転記する。
  EOT
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.principal_id }
}

output "user_assigned_identity_client_ids" {
  description = "ユーザー割り当てマネージド ID の client ID（キー => ID）。"
  value       = { for k, v in azurerm_user_assigned_identity.this : k => v.client_id }
}

output "custom_role_definition_ids" {
  description = "カスタムロール定義の resource ID（ロール名 => ID）。"
  value       = { for k, v in azurerm_role_definition.this : k => v.role_definition_resource_id }
}
