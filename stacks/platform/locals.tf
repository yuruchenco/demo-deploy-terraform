locals {
  # CAF-aligned naming: <type>-<org>-hub-<env>-<region>-<instance>
  suffix = "${var.org}-hub-${var.env}-${var.location_short}-${var.instance}"

  # Log Analytics はフィーチャーフラグで任意化しているため、
  # count = 0 のときは one() が null を返す。
  law_workspace_id = one(module.law[*].resource_id)

  # diagnostic_settings は LAW が存在する環境でのみ有効化する。
  #
  # 重要: 分岐条件には必ず var.deploy_log_analytics（plan 時点で確定する入力）を使い、
  # local.law_workspace_id（apply 時まで未確定）を使ってはならない。
  # 後者を条件にすると map のキー自体が unknown となり、
  # AVM モジュール内部の for_each = var.diagnostic_settings が
  # "Invalid for_each argument" で失敗する。
  # unknown な値はキーではなく値側にのみ置くこと。
  diagnostic_settings = var.deploy_log_analytics ? {
    toLaw = {
      name                  = "toLogAnalytics"
      workspace_resource_id = one(module.law[*].resource_id)
    }
  } : {}

  tags = merge({
    Environment = var.env
    Workload    = "hub-connectivity"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
  }, var.tags)

  # Hub subnets. Names for AzureFirewallSubnet / AzureBastionSubnet / GatewaySubnet
  # are fixed by Azure and must not be changed.
  subnets = {
    GatewaySubnet = {
      name           = "GatewaySubnet"
      address_prefix = var.subnet_address_prefixes.GatewaySubnet
    }
    AzureFirewallSubnet = {
      name           = "AzureFirewallSubnet"
      address_prefix = var.subnet_address_prefixes.AzureFirewallSubnet
    }
    AzureBastionSubnet = {
      name           = "AzureBastionSubnet"
      address_prefix = var.subnet_address_prefixes.AzureBastionSubnet
    }
    "snet-dnsresolver-inbound" = {
      name           = "snet-dnsresolver-inbound"
      address_prefix = var.subnet_address_prefixes.dnsresolver_inbound
      delegations = [{
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          name = "Microsoft.Network/dnsResolvers"
        }
      }]
    }
    "snet-dnsresolver-outbound" = {
      name           = "snet-dnsresolver-outbound"
      address_prefix = var.subnet_address_prefixes.dnsresolver_outbound
      delegations = [{
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          name = "Microsoft.Network/dnsResolvers"
        }
      }]
    }
  }
}
