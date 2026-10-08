output "intermediate_root_id" {
  description = <<-EOT
    中間ルート管理グループの resource ID（未デプロイなら null）。

    10-policy の Policy 割り当てスコープとして使用する。
    下流スタックの envs/<env>/terraform.tfvars へ手動で転記すること。
  EOT
  value       = local.intermediate_root_id
}

output "intermediate_root_name" {
  description = "中間ルート管理グループの名前（ID 部分）。"
  value       = one(azurerm_management_group.intermediate_root[*].name)
}

output "level1_management_group_ids" {
  description = "レベル1 管理グループの resource ID（キー => ID）。"
  value       = { for k, v in azurerm_management_group.level1 : k => v.id }
}

output "level2_management_group_ids" {
  description = <<-EOT
    レベル2 管理グループの resource ID（キー => ID）。

    30-identity のカスタムロール assignable_scopes、
    50-subscription-vending の払い出し先として使用する。
  EOT
  value       = { for k, v in azurerm_management_group.level2 : k => v.id }
}
