variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd). envs/<env>/<subscription_name>/terraform.tfvars ????????"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
  }
}

variable "subscription_name" {
  type        = string
  description = "????????????????????????????????check-env-consistency.sh ?????"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$", var.subscription_name))
    error_message = "subscription_name ?????????????? 3?40 ??????"
  }
}

variable "location" {
  type    = string
  default = "japaneast"
}

variable "location_short" {
  type    = string
  default = "jpe"
}

variable "department" {
  type        = string
  description = "???????????????????"
}

variable "tags" {
  type    = map(string)
  default = {}
}
