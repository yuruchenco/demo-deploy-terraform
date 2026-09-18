locals {
  # CAF-aligned naming: <type>-<org>-hub-<env>-<region>-<instance>
  suffix = "${var.org}-hub-${var.environment}-${var.location_short}-${var.instance}"

  # 診断設定は LAW の resource ID が tfvars で与えられた環境でのみ有効化する。
  #
  # 重要: 分岐条件には plan 時点で確定する入力変数のみを使う。
  # 他スタックの出力を terraform_remote_state で引くと apply まで値が
  # 未確定となり、map のキー自体が unknown になって AVM モジュール内部の
  # for_each = var.diagnostic_settings が
  # "Invalid for_each argument" で失敗する。
  # unknown な値はキーではなく値側にのみ置くこと。
  enable_diagnostics = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != ""

  diagnostic_settings = local.enable_diagnostics ? {
    toLaw = {
      name                  = "toLogAnalytics"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  } : {}

  tags = merge({
    Environment = var.environment
    Workload    = "hub-connectivity"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "20-connectivity"
  }, var.tags)

  # Hub subnets. AzureFirewallSubnet / AzureBastionSubnet / GatewaySubnet の
  # 名称は Azure 側で固定されており変更不可。
  #
  # DNS Resolver 用サブネットは 21-dns が参照するため、
  # DNS Resolver を有効化していない環境でも常に作成する
  # （サブネット自体は課金されず、後から有効化する際の手戻りを防ぐ）。
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
