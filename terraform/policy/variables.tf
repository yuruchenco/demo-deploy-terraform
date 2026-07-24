variable "subscription_id" {
  type        = string
  description = "Target subscription ID where the built-in policies are assigned."
}

variable "assignment_location" {
  type        = string
  description = "Region for the system-assigned managed identity used by DeployIfNotExists / Modify assignments. Ignored for Audit / Deny policies."
  default     = "japaneast"
}

variable "enforce" {
  type        = bool
  description = "Enforcement mode for all assignments. true = Default (effects enforced), false = DoNotEnforce (evaluate/report only, no Deny or remediation deploy)."
  default     = true
}

variable "excluded_policies" {
  type        = list(string)
  description = "Built-in policy definition GUIDs to skip (subset of the managed list). Useful to phase in Deny/DINE policies gradually."
  default     = []
}

variable "not_scopes" {
  type        = list(string)
  description = "Resource IDs (e.g. resource groups) to exclude from evaluation for every assignment."
  default     = []
}

variable "policy_parameters" {
  type        = map(string)
  description = <<-EOT
    Optional per-policy parameter overrides. Key = policy definition GUID,
    value = a JSON-encoded object of assignment parameters. All managed
    policies ship with parameter defaults, so this is only needed to override
    them (e.g. to target a specific Log Analytics workspace for the
    "Configure/Enable logging ... to Log Analytics" policies).

    Example:
      policy_parameters = {
        "2465583e-4e78-4c15-b6be-a36cbc7c8b0f" = jsonencode({
          logAnalytics = { value = "/subscriptions/.../resourceGroups/rg-mgmt/providers/Microsoft.OperationalInsights/workspaces/law-hub" }
        })
      }
  EOT
  default     = {}
}

variable "allowed_locations" {
  type        = list(string)
  description = "Value for the 'Allowed locations' (Deny) policy parameter 'listOfAllowedLocations'. Empty list keeps the policy default."
  default     = []
}
