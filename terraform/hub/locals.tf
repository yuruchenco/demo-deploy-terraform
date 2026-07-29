locals {
  # CAF-aligned naming: <type>-<org>-hub-<env>-<region>-<instance>
  suffix = "${var.org}-hub-${var.env}-${var.location_short}-${var.instance}"

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
