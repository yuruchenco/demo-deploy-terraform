###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = "Subscription ID of the Management subscription."
}

variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming (e.g. rg-<org>-mgmt-...)."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prod). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。"
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be one of: dev, stg, prod."
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region."
  default     = "japaneast"
}

variable "location_short" {
  type        = string
  description = "Short region code used in resource names (e.g. jpe for Japan East)."
  default     = "jpe"
}

variable "instance" {
  type        = string
  description = "Instance number suffix (e.g. 001)."
  default     = "001"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

###############################################################################
# Feature flags
#
# 規約 (06_フィーチャーフラグ規約): すべての deploy_* / enable_* は
# default = false（安全側）とする。各環境は envs/<env>/terraform.tfvars で
# 必要なものだけ true にオプトインする。
###############################################################################
variable "deploy_log_analytics" {
  type        = bool
  description = "Whether to deploy the central Log Analytics workspace."
  default     = false
}

variable "log_analytics_retention_days" {
  type        = number
  description = "Retention in days for the central Log Analytics workspace."
  default     = 30
}

variable "deploy_key_vault" {
  type        = bool
  description = "Whether to deploy the Hub Key Vault."
  default     = false
}

variable "key_vault_purge_protection" {
  type        = bool
  description = "Enable purge protection on the Key Vault. prod では true 必須。一度有効化すると無効化できない。"
  default     = false
}

variable "key_vault_soft_delete_days" {
  type        = number
  description = "Soft delete retention days for the Key Vault (7-90)."
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_days >= 7 && var.key_vault_soft_delete_days <= 90
    error_message = "key_vault_soft_delete_days must be between 7 and 90."
  }
}
