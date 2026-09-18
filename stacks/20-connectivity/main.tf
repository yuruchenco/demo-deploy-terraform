###############################################################################
# Resource Group (Hub / Connectivity)
###############################################################################
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

###############################################################################
# DDoS Network Protection Plan (optional - cost significant)
###############################################################################
module "ddos" {
  count = var.deploy_ddos_protection_plan ? 1 : 0

  source  = "Azure/avm-res-network-ddosprotectionplan/azurerm"
  version = "0.3.0"

  name                = "ddos-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}
