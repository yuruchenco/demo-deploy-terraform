output "assignment_ids" {
  description = "Map of policy definition GUID => policy assignment resource ID."
  value       = { for id, a in azurerm_subscription_policy_assignment.this : id => a.id }
}

output "assignment_count" {
  description = "Number of policy assignments created."
  value       = length(azurerm_subscription_policy_assignment.this)
}

output "skipped_policies" {
  description = <<-EOT
    Built-in policy GUIDs that were NOT assigned because at least one required
    parameter (no defaultValue in the definition) could not be resolved.
    Supply the missing value via the dedicated variable or var.policy_parameters
    to enable them.
  EOT
  value       = sort(local.unsatisfied_policies)
}

output "excluded_policies" {
  description = "Built-in policy GUIDs skipped explicitly via var.excluded_policies."
  value       = sort(var.excluded_policies)
}

output "managed_identity_principal_ids" {
  description = "Map of policy definition GUID => system-assigned identity principalId (DeployIfNotExists / Modify only)."
  value = {
    for id, a in azurerm_subscription_policy_assignment.this :
    id => a.identity[0].principal_id
    if length(a.identity) > 0
  }
}

output "remediation_role_assignment_count" {
  description = "Number of role assignments granted to remediation identities."
  value       = length(azurerm_role_assignment.remediation)
}
