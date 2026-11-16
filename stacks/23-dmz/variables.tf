###############################################################################
# Core / Naming
###############################################################################
variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd)."
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
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
# DMZ サブスクリプション側の前提
###############################################################################
variable "resource_group_name" {
  type        = string
  description = "DMZ 用リソースグループ名。サブスクリプション準備時（CD 外）に作成済みであること。"
}

###############################################################################
# Hub 側からの受け渡し（20-connectivity の出力を文字列で転記する）
#
# 他サブスクリプションの State は参照しない（terraform_remote_state を使わない）。
###############################################################################
variable "hub_virtual_network_id" {
  type        = string
  description = "Hub VNet の resource ID（20-connectivity の hub_vnet_id）。別サブスクリプションでもよい。"

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.hub_virtual_network_id))
    error_message = "hub_virtual_network_id must be a virtual network resource ID."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "診断設定の送信先 LAW の resource ID（40-management の出力）。null の場合は診断設定を作らない。"
  default     = null
}

###############################################################################
# Network
###############################################################################
variable "dmz_vnet_address_space" {
  type        = list(string)
  description = "DMZ VNet のアドレス空間。Hub / Spoke と重複させないこと。"
}

variable "appgw_subnet_address_prefix" {
  type        = string
  description = "Application Gateway 専用サブネットのアドレス。"
}

###############################################################################
# Feature flags
###############################################################################
variable "deploy_app_gateway" {
  type        = bool
  description = "Application Gateway (WAF_v2) と Public IP を作成するか。課金が大きいため既定は false。"
  default     = false
}

variable "app_gateway_capacity" {
  type        = number
  description = "Application Gateway の固定インスタンス数。"
  default     = 1
}

variable "app_gateway_zones" {
  type        = list(string)
  description = "Application Gateway / Public IP の可用性ゾーン。"
  default     = []
}
