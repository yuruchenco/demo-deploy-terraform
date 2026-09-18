###############################################################################
# Resource Group (DNS)
#
# 21-dns は 20-connectivity とは別の State / 別の RG を持つ。
# Private DNS Zone は変更頻度が低く影響が特大であるため、
# Firewall 等と State を共有させない。
###############################################################################
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

###############################################################################
# Private DNS Zones (centralized) + VNet links to the Hub VNet
###############################################################################
module "private_dns_zones" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "0.5.0"
  for_each = toset(var.private_dns_zones)

  domain_name = each.value
  parent_id   = module.rg.resource_id
  tags        = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = toset(var.private_dns_zones)

  name                  = "link-to-hub"
  resource_group_name   = module.rg.name
  private_dns_zone_name = each.value
  virtual_network_id    = var.hub_virtual_network_id
  registration_enabled  = false
  tags                  = local.tags

  depends_on = [module.private_dns_zones]
}

###############################################################################
# Azure DNS Private Resolver (inbound + outbound endpoints)
#
# サブネットは Hub VNet 側（20-connectivity）が所有する。
# 本スタックは名前で参照するだけで、サブネット自体は作らない。
###############################################################################
module "dns_private_resolver" {
  count = var.deploy_dns_private_resolver ? 1 : 0

  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  name                        = "dnspr-${local.suffix}"
  resource_group_name         = module.rg.name
  location                    = var.location
  virtual_network_resource_id = var.hub_virtual_network_id

  inbound_endpoints = {
    inbound = {
      name        = "inbound"
      subnet_name = var.dns_resolver_inbound_subnet_name
    }
  }

  outbound_endpoints = {
    outbound = {
      name        = "outbound"
      subnet_name = var.dns_resolver_outbound_subnet_name
    }
  }

  tags = local.tags
}
