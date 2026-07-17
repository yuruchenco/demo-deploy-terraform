###############################################################################
# Hub Virtual Network + Subnets
###############################################################################
module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = ">= 0.8.0, < 1.0.0"

  name          = "vnet-${local.suffix}"
  location      = var.location
  parent_id     = module.rg.resource_id
  address_space = var.hub_vnet_address_space
  subnets       = local.subnets
  tags          = local.tags
}

###############################################################################
# Public IPs (Firewall, Bastion)
###############################################################################
module "pip_firewall" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = ">= 0.2.0, < 1.0.0"

  name                = "pip-afw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  tags                = local.tags
}

module "pip_bastion" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = ">= 0.2.0, < 1.0.0"

  name                = "pip-bas-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  tags                = local.tags
}

###############################################################################
# Azure Firewall + Firewall Policy
###############################################################################
module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = ">= 0.3.0, < 1.0.0"

  name                = "afwp-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}

module "firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = ">= 0.3.0, < 1.0.0"

  name                = "afw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = var.firewall_sku_tier
  firewall_zones      = var.firewall_zones
  firewall_policy_id  = module.firewall_policy.resource_id

  firewall_ip_configuration = [{
    name                 = "ipconfig1"
    subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"].resource_id
    public_ip_address_id = module.pip_firewall.resource_id
  }]

  diagnostic_settings = {
    toLaw = {
      name                  = "toLogAnalytics"
      workspace_resource_id = module.law.resource_id
    }
  }

  tags = local.tags
}

###############################################################################
# Azure Bastion
###############################################################################
module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = ">= 0.6.0, < 1.0.0"

  name      = "bas-${local.suffix}"
  location  = var.location
  parent_id = module.rg.resource_id
  sku       = var.bastion_sku
  zones     = var.bastion_zones

  ip_configuration = {
    name                 = "ipconfig"
    subnet_id            = module.hub_vnet.subnets["AzureBastionSubnet"].resource_id
    create_public_ip     = false
    public_ip_address_id = module.pip_bastion.resource_id
  }

  tags = local.tags
}

###############################################################################
# Route Table for Spoke egress (0.0.0.0/0 -> Azure Firewall)
# Associated to spoke subnets when spokes are deployed. Exposed via outputs.
###############################################################################
module "route_table_spoke" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = ">= 0.4.0, < 1.0.0"

  name                = "route-${var.org}-spoke-egress-${var.env}-${var.location_short}-${var.instance}"
  resource_group_name = module.rg.name
  location            = var.location

  routes = {
    default = {
      name                   = "default-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall.resource.ip_configuration[0].private_ip_address
    }
  }

  tags = local.tags
}

###############################################################################
# Private DNS Zones (centralized in Hub) + VNet links to the Hub VNet
###############################################################################
module "private_dns_zones" {
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = ">= 0.3.0, < 1.0.0"
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
  virtual_network_id    = module.hub_vnet.resource_id
  registration_enabled  = false
  tags                  = local.tags

  depends_on = [module.private_dns_zones]
}

###############################################################################
# Azure DNS Private Resolver (inbound + outbound endpoints)
###############################################################################
module "dns_private_resolver" {
  count = var.deploy_dns_private_resolver ? 1 : 0

  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = ">= 0.7.0, < 1.0.0"

  name                        = "dnspr-${local.suffix}"
  resource_group_name         = module.rg.name
  location                    = var.location
  virtual_network_resource_id = module.hub_vnet.resource_id

  inbound_endpoints = {
    inbound = {
      name        = "inbound"
      subnet_name = "snet-dnsresolver-inbound"
    }
  }

  outbound_endpoints = {
    outbound = {
      name        = "outbound"
      subnet_name = "snet-dnsresolver-outbound"
    }
  }

  tags = local.tags
}

###############################################################################
# ExpressRoute / VPN Virtual Network Gateway (optional)
# No AVM resource module is published for the VNet Gateway, so the native
# azurerm resource is used here. Gated by var.deploy_expressroute_gateway.
###############################################################################
resource "azurerm_public_ip" "gateway" {
  count = var.deploy_expressroute_gateway && var.gateway_type == "Vpn" ? 1 : 0

  name                = "pip-vgw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.firewall_zones
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  count = var.deploy_expressroute_gateway ? 1 : 0

  name                = "vgw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  type                = var.gateway_type
  sku                 = var.gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = var.gateway_type == "Vpn" ? azurerm_public_ip.gateway[0].id : null
    subnet_id                     = module.hub_vnet.subnets["GatewaySubnet"].resource_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}
