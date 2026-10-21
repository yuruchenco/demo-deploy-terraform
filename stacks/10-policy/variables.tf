variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。リソースでは参照しないが、環境取り違えチェック（.github/scripts/check-env-consistency.sh）の判定キーとして全スタックで必須とする。"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
  }
}

variable "assignment_name_suffix" {
  description = "割り当て名の末尾に付与する環境識別子（例: -stg）。同一サブスクリプションに複数環境を作る場合の名前衝突を避ける。サブスクリプション スコープの割り当て名は 64 文字以内（GUID 36 文字 + suffix）。"
  type        = string
  default     = ""

  validation {
    condition     = length(var.assignment_name_suffix) <= 20
    error_message = "assignment_name_suffix は 20 文字以内にしてください。"
  }
}

variable "assignment_location" {
  type        = string
  description = "Region for the system-assigned managed identity used by DeployIfNotExists / Modify assignments. Ignored for Audit / Deny policies."
  default     = "japaneast"
}

variable "enforce" {
  type        = bool
  description = <<-EOT
    Enforcement mode for all assignments. true = Default (effects enforced),
    false = DoNotEnforce (evaluate/report only, no Deny or remediation deploy).

    既定は false（安全側）。Deny / DeployIfNotExists が既存環境を
    いきなり止めることを防ぐため、まず DoNotEnforce で影響を観測し、
    環境ごとに envs/<env>/terraform.tfvars で明示的に true へ切り替える。
  EOT
  default     = false
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

variable "log_analytics_workspace_id" {
  type        = string
  description = <<-EOT
    Resource ID of the central Log Analytics workspace. Wired automatically into
    the 'logAnalytics' parameter of the 31 built-in DeployIfNotExists diagnostic /
    logging policies (these have no default value and would otherwise fail with
    MissingPolicyParameter). Leave empty to skip wiring (those policies will fail
    unless excluded or supplied via policy_parameters).
  EOT
  default     = ""
}

variable "max_days_to_rotate" {
  type        = number
  description = "Value for the 'Keys should have a rotation policy' (d8cf8476) parameter 'maximumDaysToRotate'. Required (no default in the definition)."
  default     = 90
}

variable "activity_log_alert_administrative_operation" {
  type        = string
  description = <<-EOT
    operationName for 'An activity log alert should exist for specific Administrative
    operations' (b954148f). Empty string skips the assignment.
    Allowed values (enforced by the definition):
      Microsoft.Sql/servers/firewallRules/{write,delete}
      Microsoft.Network/networkSecurityGroups/{write,delete}
      Microsoft.Network/networkSecurityGroups/securityRules/{write,delete}
      Microsoft.ClassicNetwork/... equivalents
  EOT
  default     = "Microsoft.Network/networkSecurityGroups/write"
}

variable "activity_log_alert_policy_operation" {
  type        = string
  description = "operationName for 'An activity log alert should exist for specific Policy operations' (c5447c04). Allowed: Microsoft.Authorization/policyAssignments/{write,delete}. Empty string skips the assignment."
  default     = "Microsoft.Authorization/policyAssignments/write"
}

variable "activity_log_alert_security_operation" {
  type        = string
  description = "operationName for 'An activity log alert should exist for specific Security operations' (3b980d31). Allowed: Microsoft.Security/policies/write, Microsoft.Security/securitySolutions/{write,delete}. Empty string skips the assignment."
  default     = "Microsoft.Security/policies/write"
}
