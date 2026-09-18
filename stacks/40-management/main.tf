###############################################################################
# Resource Group (Management)
#
# 本スタックは 20-connectivity から独立して実行できる。
# Key Vault は Private Endpoint を張らず public_network_access_enabled = false
# のみで閉じているため、Hub のサブネットに依存しない。
###############################################################################
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

###############################################################################
# Central Log Analytics Workspace
#
# 本ワークスペースの resource ID は output し、
# 20-connectivity / 10-policy の tfvars に明示的に受け渡す。
# terraform_remote_state で暗黙参照しないのは、
# plan 時点で値が未確定になり for_each / count が壊れるのを避けるため。
###############################################################################
module "law" {
  count = var.deploy_log_analytics ? 1 : 0

  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                      = "log-${local.suffix}"
  resource_group_name                       = module.rg.name
  location                                  = var.location
  log_analytics_workspace_retention_in_days = var.log_analytics_retention_days
  tags                                      = local.tags
}

###############################################################################
# Key Vault (platform shared secrets / certificates)
###############################################################################
resource "random_string" "kv" {
  count = var.deploy_key_vault ? 1 : 0

  length  = 4
  special = false
  upper   = false
}

module "key_vault" {
  count = var.deploy_key_vault ? 1 : 0

  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = "kv-${var.org}-mgmt-${var.environment}-${random_string.kv[0].result}"
  resource_group_name = module.rg.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  purge_protection_enabled   = var.key_vault_purge_protection
  soft_delete_retention_days = var.key_vault_soft_delete_days

  public_network_access_enabled = false
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  # 条件には plan 時点で確定する var.deploy_log_analytics を使う。
  # local の workspace ID（apply まで未確定）を条件にすると
  # map のキーが unknown となり、AVM 内部の
  # for_each = var.diagnostic_settings が失敗する。
  diagnostic_settings = var.deploy_log_analytics ? {
    toLaw = {
      name                  = "toLogAnalytics"
      workspace_resource_id = one(module.law[*].resource_id)
    }
  } : {}

  tags = local.tags
}
