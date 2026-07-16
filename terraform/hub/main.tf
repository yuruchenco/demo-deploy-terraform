###############################################################################
# Resource Group (Hub / Connectivity)
###############################################################################
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.2"

  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

###############################################################################
# Monitoring - Central Log Analytics Workspace
###############################################################################
module "law" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4"

  name                                      = "log-${local.suffix}"
  resource_group_name                       = module.rg.name
  location                                  = var.location
  log_analytics_workspace_retention_in_days = var.log_analytics_retention_days
  tags                                      = local.tags
}

###############################################################################
# Key Vault (Hub shared secrets / certificates)
###############################################################################
resource "random_string" "kv" {
  length  = 4
  special = false
  upper   = false
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  name                = "kv-${var.org}-hub-${random_string.kv.result}"
  resource_group_name = module.rg.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  diagnostic_settings = {
    toLaw = {
      name                  = "toLogAnalytics"
      workspace_resource_id = module.law.resource_id
    }
  }

  tags = local.tags
}

###############################################################################
# DDoS Network Protection Plan (optional - cost significant)
###############################################################################
module "ddos" {
  count = var.deploy_ddos_protection_plan ? 1 : 0

  source  = "Azure/avm-res-network-ddosprotectionplan/azurerm"
  version = "~> 0.2"

  name                = "ddos-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}
