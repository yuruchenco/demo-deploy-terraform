###############################################################################
# Hub Virtual Network + Subnets
#
# VNet とサブネットはフラグで制御しない。課金が発生せず、
# 21-dns / 22-gateway が参照する前提リソースであるため常に作成する。
###############################################################################
module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

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
  count = var.deploy_firewall ? 1 : 0

  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = "pip-afw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  ip_tags             = { FirstPartyUsage = "/Unprivileged" }
  tags                = local.tags
}

module "pip_bastion" {
  count = var.deploy_bastion ? 1 : 0

  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = "pip-bas-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  zones               = []
  ip_tags             = { FirstPartyUsage = "/Unprivileged" }
  tags                = local.tags
}

###############################################################################
# Azure Firewall + Firewall Policy
###############################################################################
module "firewall_policy" {
  count = var.deploy_firewall ? 1 : 0

  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = "afwp-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "app" {
  for_each = var.deploy_firewall ? { for c in var.firewall_policy_rules : c.name => c } : {}

  name               = each.value.name
  firewall_policy_id = module.firewall_policy[0].resource_id
  priority           = each.value.priority

  application_rule_collection {
    name     = each.value.name
    priority = each.value.priority
    action   = "Allow"

    dynamic "rule" {
      for_each = each.value.rules
      content {
        name              = rule.value.name
        source_addresses  = rule.value.source_addresses
        destination_fqdns = rule.value.destination_fqdns

        dynamic "protocols" {
          for_each = rule.value.protocols
          content {
            type = protocols.value.type
            port = protocols.value.port
          }
        }
      }
    }
  }
}

module "firewall" {
  count = var.deploy_firewall ? 1 : 0

  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = "afw-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = var.firewall_sku_tier
  firewall_zones      = var.firewall_zones
  firewall_policy_id  = module.firewall_policy[0].resource_id

  firewall_ip_configuration = [{
    name                 = "ipconfig1"
    subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"].resource_id
    public_ip_address_id = module.pip_firewall[0].resource_id
  }]

  diagnostic_settings = local.diagnostic_settings

  tags = local.tags
}

###############################################################################
# Azure Bastion
###############################################################################
module "bastion" {
  count = var.deploy_bastion ? 1 : 0

  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  name      = "bas-${local.suffix}"
  location  = var.location
  parent_id = module.rg.resource_id
  sku       = var.bastion_sku
  zones     = var.bastion_zones

  ip_configuration = {
    name                 = "ipconfig"
    subnet_id            = module.hub_vnet.subnets["AzureBastionSubnet"].resource_id
    create_public_ip     = false
    public_ip_address_id = module.pip_bastion[0].resource_id
  }

  tags = local.tags
}

###############################################################################
# Route Table for Spoke egress (0.0.0.0/0 -> Azure Firewall)
###############################################################################
module "route_table_spoke" {
  count = var.deploy_route_table ? 1 : 0

  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  name                = "route-${var.org}-spoke-egress-${var.environment}-${var.location_short}-${var.instance}"
  resource_group_name = module.rg.name
  location            = var.location

  routes = {
    default = {
      name                   = "default-to-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.firewall[0].resource.ip_configuration[0].private_ip_address
    }
  }

  tags = local.tags
}
