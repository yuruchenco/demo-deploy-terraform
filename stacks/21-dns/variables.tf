###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = "Subscription ID of the Connectivity (Hub) subscription."
}

variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prod)."
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
  description = "Short region code used in resource names."
  default     = "jpe"
}

variable "instance" {
  type        = string
  description = "Instance number suffix."
  default     = "001"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

###############################################################################
# 20-connectivity からの受け渡し
#
# terraform_remote_state で暗黙参照せず、tfvars で明示的に渡す。
# 依存関係をレビュー可能な差分として可視化し、
# plan 時点で値を確定させるための意図的な設計。
###############################################################################
variable "hub_virtual_network_id" {
  type        = string
  description = "Resource ID of the Hub VNet produced by 20-connectivity. Private DNS zone の VNet link と DNS Private Resolver が参照する。"
}

###############################################################################
# Feature flags
###############################################################################
variable "private_dns_zones" {
  type        = list(string)
  description = "Private DNS zones to host centrally and link to the Hub VNet. 既定は空。"
  default     = []
}

variable "deploy_dns_private_resolver" {
  type        = bool
  description = "Whether to deploy the Azure DNS Private Resolver with inbound/outbound endpoints. Hub VNet 側に専用サブネットが必要。"
  default     = false
}

variable "dns_resolver_inbound_subnet_name" {
  type        = string
  description = "Name of the delegated inbound endpoint subnet inside the Hub VNet."
  default     = "snet-dnsresolver-inbound"
}

variable "dns_resolver_outbound_subnet_name" {
  type        = string
  description = "Name of the delegated outbound endpoint subnet inside the Hub VNet."
  default     = "snet-dnsresolver-outbound"
}
