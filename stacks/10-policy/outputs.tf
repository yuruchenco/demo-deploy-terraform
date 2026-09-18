output "assignment_ids" {
  description = "Map of policy definition GUID => policy assignment resource ID."
  value       = { for id, a in azurerm_subscription_policy_assignment.this : id => a.id }
}

output "assignment_count" {
  description = "Number of policy assignments created."
  value       = length(azurerm_subscription_policy_assignment.this)
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
