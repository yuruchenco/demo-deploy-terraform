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
  description = "Environment token (dev / stg / prd). 本スタックは dev には存在しない。"
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
# 20-connectivity からの受け渡し
###############################################################################
variable "resource_group_name" {
  type        = string
  description = "Name of the Hub resource group created by 20-connectivity."
}

variable "gateway_subnet_id" {
  type        = string
  description = "Resource ID of the GatewaySubnet inside the Hub VNet (20-connectivity の hub_subnet_ids 出力を転記する)。"
}

###############################################################################
# Feature flags
#
# 排他的な種別選択は bool を並べず <対象>_type + validation で表現する
# (06_フィーチャーフラグ規約 #7)。既定値に None を含めることで
# 「作らない」が安全側のデフォルトになる。
###############################################################################
variable "gateway_type" {
  type        = string
  description = "Gateway type: None (作らない) / Vpn / ExpressRoute."
  default     = "None"

  validation {
    condition     = contains(["None", "Vpn", "ExpressRoute"], var.gateway_type)
    error_message = "gateway_type must be None, Vpn or ExpressRoute."
  }
}

variable "gateway_sku" {
  type        = string
  description = "Gateway SKU (e.g. VpnGw1AZ for VPN, ErGw1AZ for ExpressRoute). gateway_type != None のとき必須。"
  default     = null

  validation {
    condition     = var.gateway_type == "None" || var.gateway_sku != null
    error_message = "gateway_sku is required when gateway_type is not None."
  }
}

variable "deploy_gateway_public_ip" {
  type        = bool
  description = "Whether to create a Public IP for the gateway. VPN 時のみ必要。ExpressRoute で true にするとエラーになる。"
  default     = false

  validation {
    condition     = var.gateway_type != "ExpressRoute" || var.deploy_gateway_public_ip == false
    error_message = "deploy_gateway_public_ip must be false when gateway_type is ExpressRoute."
  }

  validation {
    condition     = var.gateway_type != "Vpn" || var.deploy_gateway_public_ip == true
    error_message = "deploy_gateway_public_ip must be true when gateway_type is Vpn."
  }
}

variable "gateway_public_ip_zones" {
  type        = list(string)
  description = "Availability zones for the gateway Public IP."
  default     = ["1", "2", "3"]
}
