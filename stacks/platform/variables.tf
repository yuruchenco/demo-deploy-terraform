###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = "Subscription ID of the Platform/Connectivity (Hub) subscription."
}

variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming (e.g. rg-<org>-hub-...)."
  default     = "masuda"
}

variable "env" {
  type        = string
  description = "Environment token (dev / stg / prd). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "env must be one of: dev, stg, prd."
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region for the Hub."
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
# 規約: すべての deploy_* は default = false（安全側）とする。
# 各環境は envs/<env>/terraform.tfvars で必要なものだけ true にオプトインする。
# これにより、dev で追加したリソースが prd へ暗黙に波及することを防ぐ。
#
# リソースグループと Hub VNet / サブネットは課金が発生しないため常に作成する。
###############################################################################
variable "deploy_log_analytics" {
  type        = bool
  description = "Whether to deploy the central Log Analytics workspace. false の場合、各リソースの diagnostic_settings も無効化される。"
  default     = false
}

variable "deploy_key_vault" {
  type        = bool
  description = "Whether to deploy the Hub Key Vault."
  default     = false
}

variable "deploy_firewall" {
  type        = bool
  description = "Whether to deploy Azure Firewall (+ Firewall Policy + Public IP). 費用が大きい。"
  default     = false
}

variable "deploy_bastion" {
  type        = bool
  description = "Whether to deploy Azure Bastion (+ Public IP). 費用が大きい。"
  default     = false
}

variable "deploy_route_table" {
  type        = bool
  description = "Whether to deploy the spoke egress route table. next hop に Firewall の private IP を使うため、deploy_firewall = true が前提。"
  default     = false

  validation {
    condition     = var.deploy_route_table ? var.deploy_firewall : true
    error_message = "deploy_route_table = true requires deploy_firewall = true (next hop needs the firewall private IP)."
  }
}

###############################################################################
# Network
###############################################################################
variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space of the Hub VNet. MUST NOT overlap with on-prem or existing Azure ranges (design item Q4)."
  default     = ["10.0.0.0/22"]
}

variable "subnet_address_prefixes" {
  type = object({
    GatewaySubnet        = string
    AzureFirewallSubnet  = string
    AzureBastionSubnet   = string
    dnsresolver_inbound  = string
    dnsresolver_outbound = string
  })
  description = "Address prefixes for the Hub subnets. AzureFirewallSubnet/AzureBastionSubnet require /26 or larger; GatewaySubnet /27 or larger."
  default = {
    GatewaySubnet        = "10.0.0.0/27"
    AzureFirewallSubnet  = "10.0.0.64/26"
    AzureBastionSubnet   = "10.0.0.128/26"
    dnsresolver_inbound  = "10.0.1.0/28"
    dnsresolver_outbound = "10.0.1.16/28"
  }
}

variable "private_dns_zones" {
  type        = list(string)
  description = "Private DNS zones to host centrally in the Hub and link to the Hub VNet. 既定は空。必要なゾーンを envs/<env>/terraform.tfvars で明示的に指定する。"
  default     = []
}

###############################################################################
# Firewall
###############################################################################
variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier: Basic, Standard, or Premium (design item Q6)."
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Basic, Standard or Premium."
  }
}

variable "firewall_zones" {
  type        = list(string)
  description = "Availability zones for the Azure Firewall."
  default     = ["1", "2", "3"]
}

###############################################################################
# Bastion
###############################################################################
variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU: Basic, Standard, or Premium."
  default     = "Standard"
}

variable "bastion_zones" {
  type        = list(string)
  description = "Availability zones for Azure Bastion. Leave empty ([]) in regions that do not support Bastion zonal deployment (e.g. japaneast)."
  default     = []
}

###############################################################################
# ExpressRoute / VPN Gateway
###############################################################################
variable "deploy_expressroute_gateway" {
  type        = bool
  description = "Whether to deploy an ExpressRoute Virtual Network Gateway (design item Q5). 作成に30-45分かかり費用も大きい。"
  default     = false
}

variable "gateway_type" {
  type        = string
  description = "Gateway type: ExpressRoute or Vpn."
  default     = "ExpressRoute"
  validation {
    condition     = contains(["ExpressRoute", "Vpn"], var.gateway_type)
    error_message = "gateway_type must be ExpressRoute or Vpn."
  }
}

variable "gateway_sku" {
  type        = string
  description = "Gateway SKU (e.g. ErGw1AZ for ExpressRoute, VpnGw1AZ for VPN)."
  default     = "ErGw1AZ"
}

###############################################################################
# DNS Private Resolver
###############################################################################
variable "deploy_dns_private_resolver" {
  type        = bool
  description = "Whether to deploy the Azure DNS Private Resolver with inbound/outbound endpoints."
  default     = false
}

###############################################################################
# DDoS
###############################################################################
variable "deploy_ddos_protection_plan" {
  type        = bool
  description = "Whether to deploy a DDoS Network Protection Plan (cost significant; design item Q6)."
  default     = false
}

###############################################################################
# Monitoring
###############################################################################
variable "log_analytics_retention_days" {
  type        = number
  description = "Retention in days for the central Log Analytics workspace (design item Q8)."
  default     = 90
}
