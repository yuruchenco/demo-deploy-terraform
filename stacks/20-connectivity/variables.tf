###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = "Subscription ID of the Connectivity (Hub) subscription."
}

variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming (e.g. rg-<org>-hub-...)."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。"
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
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
# 40-management からの受け渡し（任意）
###############################################################################
variable "log_analytics_workspace_id" {
  type        = string
  description = <<-EOT
    Resource ID of the central Log Analytics workspace produced by 40-management.
    null / "" のときは診断設定を作成しない。

    terraform_remote_state で暗黙参照せず tfvars で明示的に渡す。
    plan 時点で値が確定しないと AVM 内部の for_each が
    "Invalid for_each argument" で失敗するため。
  EOT
  default     = null
}

###############################################################################
# Feature flags
#
# 規約 (06_フィーチャーフラグ規約): すべての deploy_* は default = false。
# リソースグループ / Hub VNet / サブネットは課金が発生せず、
# 後続スタックの前提でもあるため常に作成する。
###############################################################################
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

variable "deploy_subnet_nsgs" {
  type        = bool
  description = <<-EOT
    Whether to create and attach NSGs to AzureBastionSubnet and the DNS Resolver subnets.

    プラットフォーム側の Azure Policy が DeployIfNotExists で NSG を自動付与する
    環境では true のままにすること。false にすると Policy が NSG を付与し、
    以後 plan のたびに「NSG を外す」差分が出続ける。
    AzureFirewallSubnet（NSG 付与不可）と GatewaySubnet は対象外。
  EOT
  default     = true
}

variable "deploy_route_table" {
  type        = bool
  description = "Whether to deploy the spoke egress route table. next hop に Firewall の private IP を使うため deploy_firewall = true が前提。"
  default     = false

  validation {
    condition     = var.deploy_route_table ? var.deploy_firewall : true
    error_message = "deploy_route_table = true requires deploy_firewall = true (next hop needs the firewall private IP)."
  }
}

variable "deploy_ddos_protection_plan" {
  type        = bool
  description = "Whether to deploy a DDoS Network Protection Plan. 【高額】prd のみ有効化する。"
  default     = false
}

###############################################################################
# Network
###############################################################################
variable "hub_vnet_address_space" {
  type        = list(string)
  description = "Address space of the Hub VNet. 環境間・オンプレと重複しないこと。"
  default     = []

  validation {
    condition     = length(var.hub_vnet_address_space) > 0
    error_message = "hub_vnet_address_space must be set in envs/<env>/terraform.tfvars."
  }
}

variable "subnet_address_prefixes" {
  type = object({
    GatewaySubnet        = string
    AzureFirewallSubnet  = string
    AzureBastionSubnet   = string
    dnsresolver_inbound  = string
    dnsresolver_outbound = string
  })
  description = "Address prefixes for the Hub subnets. AzureFirewallSubnet / AzureBastionSubnet は /26 以上、GatewaySubnet は /27 以上が必要。"
}

###############################################################################
# Firewall
###############################################################################
variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier: Basic, Standard, or Premium."
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Basic, Standard or Premium."
  }
}

variable "firewall_zones" {
  type        = list(string)
  description = "Availability zones for the Azure Firewall."
  default     = []
}

variable "firewall_policy_rules" {
  type = list(object({
    name     = string
    priority = number
    rules = list(object({
      name                  = string
      protocols             = optional(list(object({ type = string, port = number })), [])
      source_addresses      = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
      destination_addresses = optional(list(string), [])
      destination_ports     = optional(list(string), [])
    }))
  }))
  description = "Application rule collections injected into the Firewall Policy. コードに直書きせず tfvars から注入する (05_環境差分マトリクス #8)。"
  default     = []
}

###############################################################################
# Bastion
###############################################################################
variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU: Basic, Standard, or Premium."
  default     = "Basic"
}

variable "bastion_zones" {
  type        = list(string)
  description = "Availability zones for Azure Bastion. japaneast は Bastion の AZ 指定に非対応のため [] とする。"
  default     = []
}
