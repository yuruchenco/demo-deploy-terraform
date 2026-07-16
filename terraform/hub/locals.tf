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
      name             = "GatewaySubnet"
      address_prefixes = [var.subnet_address_prefixes.GatewaySubnet]
    }
    AzureFirewallSubnet = {
      name             = "AzureFirewallSubnet"
      address_prefixes = [var.subnet_address_prefixes.AzureFirewallSubnet]
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.subnet_address_prefixes.AzureBastionSubnet]
    }
    "snet-dnsresolver-inbound" = {
      name             = "snet-dnsresolver-inbound"
      address_prefixes = [var.subnet_address_prefixes.dnsresolver_inbound]
      delegation = [{
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          name    = "Microsoft.Network/dnsResolvers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
    "snet-dnsresolver-outbound" = {
      name             = "snet-dnsresolver-outbound"
      address_prefixes = [var.subnet_address_prefixes.dnsresolver_outbound]
      delegation = [{
        name = "Microsoft.Network.dnsResolvers"
        service_delegation = {
          name    = "Microsoft.Network/dnsResolvers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    }
  }
}
