###############################################################################
# Subscription-scoped built-in policy assignments
#
# Source of truth: PolicyList.csv (57 unique built-in policy definitions).
# Each entry is classified by its default effect so that DeployIfNotExists /
# Modify policies automatically receive a system-assigned managed identity,
# a location, and the role assignments their remediation tasks require.
###############################################################################

locals {
  subscription_scope     = "/subscriptions/${var.subscription_id}"
  policy_definition_base = "/providers/Microsoft.Authorization/policyDefinitions"

  # Effects that require a managed identity + location + remediation roles.
  identity_effects = ["DeployIfNotExists", "Modify"]

  # ----------------------------------------------------------------------------
  # Managed built-in policies (GUID => effect + friendly display name).
  # Generated from PolicyList.csv; keep in sync when the CSV changes.
  # ----------------------------------------------------------------------------
  policies = {
    "5807e1b4-ba5e-4718-8689-a0ca05a191b2" = { effect = "None", display = "Microsoft Managed Control 1054 - Session Termination" }
    "83a86a26-fd1f-447c-b59d-e51f44264114" = { effect = "None", display = "Network interfaces should not have public IPs" }
    "ee7495e7-3ba7-40b6-bfee-c29e22cc75d4" = { effect = "Audit", display = "API Management APIs should use only encrypted protocols" }
    "a4af4a39-4135-47fb-b175-47fbdf85311d" = { effect = "Audit", display = "App Service apps should only be accessible over HTTPS" }
    "470baccb-7e51-4549-8b1a-3e5be069f663" = { effect = "Audit", display = "Azure Cache for Redis should disable public network access" }
    "797b37f7-06b8-444c-b1ad-fc62867f335a" = { effect = "Audit", display = "Azure Cosmos DB should disable public network access" }
    "51c1490f-3319-459c-bbbc-7f391bbed753" = { effect = "Audit", display = "Azure Databricks Clusters should disable public IP" }
    "6a92fe1f-0b86-44ae-843d-2db3d2b571ae" = { effect = "Audit", display = "ElasticSan should disable public network access" }
    "d8cf8476-a2ec-4916-896e-992351803c44" = { effect = "Audit", display = "Keys should have a rotation policy ensuring that their rotation is scheduled within the specified number of days after creation." }
    "8405fdab-1faf-48aa-b702-999c9c172094" = { effect = "Audit", display = "Managed disks should disable public network access" }
    "43bc7be6-5e69-4b0d-a2bb-e815557ca673" = { effect = "Audit", display = "Public network access on Azure Data Explorer should be disabled" }
    "1cf164be-6819-4a50-b8fa-4bcaa4f98fb6" = { effect = "Audit", display = "Public network access on Azure Data Factory should be disabled" }
    "1b8ca024-1d5c-4dec-8995-b1a932b41780" = { effect = "Audit", display = "Public network access on Azure SQL Database should be disabled" }
    "fe83a0eb-a853-422d-aac2-1bffd182c5d0" = { effect = "Audit", display = "Storage accounts should have the specified minimum TLS version" }
    "2a1a9cdf-e04d-429a-8416-3bfb72a1b26f" = { effect = "Audit", display = "Storage accounts should restrict network access using virtual network rules" }
    "b954148f-4c11-4c38-8221-be76711e194a" = { effect = "AuditIfNotExists", display = "An activity log alert should exist for specific Administrative operations" }
    "c5447c04-a4d7-4ba8-a263-c9ee321a6858" = { effect = "AuditIfNotExists", display = "An activity log alert should exist for specific Policy operations" }
    "3b980d31-7904-4bb7-8575-5665739a8052" = { effect = "AuditIfNotExists", display = "An activity log alert should exist for specific Security operations" }
    "e56962a6-4747-49cd-b67b-bf8b01975c4c" = { effect = "Deny", display = "Allowed locations" }
    "2465583e-4e78-4c15-b6be-a36cbc7c8b0f" = { effect = "DeployIfNotExists", display = "Configure Azure Activity logs to stream to specified Log Analytics workspace" }
    "b4fe1a3b-0715-4c6c-a5ea-ffc33cf823cb" = { effect = "DeployIfNotExists", display = "Configure diagnostic settings for Blob Services to Log Analytics workspace" }
    "25a70cc8-2bd4-47f1-90b6-1478e4662c96" = { effect = "DeployIfNotExists", display = "Configure diagnostic settings for File Services to Log Analytics workspace" }
    "7bd000e3-37c7-4928-9f31-86c4b77c5c45" = { effect = "DeployIfNotExists", display = "Configure diagnostic settings for Queue Services to Log Analytics workspace" }
    "2fb86bf3-d221-43d1-96d1-2434af34eaa0" = { effect = "DeployIfNotExists", display = "Configure diagnostic settings for Table Services to Log Analytics workspace" }
    "c9ddb292-b203-4738-aead-18e2716e858f" = { effect = "DeployIfNotExists", display = "Configure Microsoft Defender for Containers to be enabled" }
    "5eb6d64a-4086-4d7a-92da-ec51aed0332d" = { effect = "DeployIfNotExists", display = "Configure Microsoft Defender for Servers plan" }
    "98903777-a9f6-47f5-90a9-acaf62ab01a8" = { effect = "DeployIfNotExists", display = "Configure subscriptions to enable service health alert monitoring rule" }
    "3e9965dc-cc13-47ca-8259-a4252fd0cf7b" = { effect = "DeployIfNotExists", display = "Configure virtual network to enable Flow Log and Traffic Analytics" }
    "cd6f7aff-2845-4dab-99f2-6d1754a754b0" = { effect = "DeployIfNotExists", display = "Deploy a Flow Log resource with target virtual network" }
    "567c93f7-3661-494f-a30f-0a94d9bfebf8" = { effect = "DeployIfNotExists", display = "Enable logging by category group for API Management services (microsoft.apimanagement/service) to Log Analytics" }
    "c0d8e23a-47be-4032-961f-8b0ff3957061" = { effect = "DeployIfNotExists", display = "Enable logging by category group for App Service (microsoft.web/sites) to Log Analytics" }
    "92012204-a7e4-4a95-bbe5-90d0d3e12735" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Application gateways (microsoft.network/applicationgateways) to Log Analytics" }
    "aec4c33f-2f2a-4fd3-91cd-24a939513c60" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Azure Cache for Redis (microsoft.cache/redis) to Log Analytics" }
    "68ba9fc9-71b9-4e6f-9cf5-ecc07722324c" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Azure Cosmos DB accounts (microsoft.documentdb/databaseaccounts) to Log Analytics" }
    "a819f227-229d-44cb-8ad6-25becdb4451f" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Azure Data Explorer Clusters (microsoft.kusto/clusters) to Log Analytics" }
    "454c7d4b-c141-43f1-8c81-975ebb15a9b5" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Azure Databricks Services (microsoft.databricks/workspaces) to Log Analytics" }
    "305408ed-dd5a-43b9-80c1-9eea87a176bb" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Azure Synapse Analytics (microsoft.synapse/workspaces) to Log Analytics" }
    "f8352124-56fa-4f94-9441-425109cdc14b" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Bastions (microsoft.network/bastionhosts) to Log Analytics" }
    "415eaa04-e9db-476a-ba43-092d70ebe1e7" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Bot Services (microsoft.botservice/botservices) to Log Analytics" }
    "fa570aa1-acca-4eea-8e5a-233cf2c5e4c2" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Caches (microsoft.cache/redisenterprise/databases) to Log Analytics" }
    "6a664864-e2b5-413e-b930-f11caa132f16" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Container Apps Environments (microsoft.app/managedenvironments) to Log Analytics" }
    "d111f33e-5cb3-414e-aec4-427e7d1080c9" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Data Lake Analytics (microsoft.datalakeanalytics/accounts) to Log Analytics" }
    "dfe69c56-9c12-4271-9e62-7607ab669582" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Data Lake Storage Gen1 (microsoft.datalakestore/accounts) to Log Analytics" }
    "a271e156-b295-4537-b01d-09675d9e7851" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Dedicated SQL pools (microsoft.synapse/workspaces/sqlpools) to Log Analytics" }
    "6201aeb7-2b5c-4671-8ab4-5d3ba4d77f3b" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Front Door and CDN profiles (microsoft.cdn/profiles) to Log Analytics" }
    "a7c668bd-3327-474f-8fb5-8146e3e40e40" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Host pools (microsoft.desktopvirtualization/hostpools) to Log Analytics" }
    "6b359d8f-f88d-4052-aa7c-32015963ecc1" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Key vaults (microsoft.keyvault/vaults) to Log Analytics" }
    "b88bfd90-4da5-43eb-936f-ae1481924291" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Managed HSMs (microsoft.keyvault/managedhsms) to Log Analytics" }
    "ae0fc3d3-c9ce-43e8-923a-a143db56d81e" = { effect = "DeployIfNotExists", display = "Enable logging by category group for microsoft.documentdb/cassandraclusters to Log Analytics" }
    "064a3695-3197-4354-816b-65c7b952db9e" = { effect = "DeployIfNotExists", display = "Enable logging by category group for microsoft.documentdb/mongoclusters to Log Analytics" }
    "5cfb9e8a-2f13-40bd-a527-c89bc596d299" = { effect = "DeployIfNotExists", display = "Enable logging by category group for microsoft.machinelearningservices/workspaces/onlineendpoints to Log Analytics" }
    "887dc342-c6bd-418b-9407-ab0e27deba36" = { effect = "DeployIfNotExists", display = "Enable logging by category group for microsoft.synapse/workspaces/kustopools to Log Analytics" }
    "6567d3f3-42d0-4cfb-9606-9741ba60fa07" = { effect = "DeployIfNotExists", display = "Enable logging by category group for SQL databases (microsoft.sql/servers/databases) to Log Analytics" }
    "8fc4ca5f-6abc-4b30-9565-0bd91ac49420" = { effect = "DeployIfNotExists", display = "Enable logging by category group for SQL managed instances (microsoft.sql/managedinstances) to Log Analytics" }
    "0da6faeb-d6c6-4f6e-9f49-06277493270b" = { effect = "DeployIfNotExists", display = "Enable logging by category group for Web PubSub Service (microsoft.signalrservice/webpubsub) to Log Analytics" }
    "a18c77f2-3d6d-497a-9f61-849a7e8a3b79" = { effect = "Modify", display = "Configure App Service app slots to only be accessible over HTTPS" }
    "f81e3117-0093-4b17-8a60-82363134f0eb" = { effect = "Modify", display = "Configure secure transfer of data on a storage account" }
  }

  # Apply exclusions.
  assigned_policies = {
    for id, meta in local.policies : id => meta
    if !contains(var.excluded_policies, id)
  }

  # Subset that needs a managed identity (DeployIfNotExists / Modify).
  identity_policies = {
    for id, meta in local.assigned_policies : id => meta
    if contains(local.identity_effects, meta.effect)
  }

  # Built-in convenience parameter wiring for the "Allowed locations" Deny policy.
  allowed_locations_policy_id = "e56962a6-4747-49cd-b67b-bf8b01975c4c"
  allowed_locations_parameters = length(var.allowed_locations) > 0 ? {
    (local.allowed_locations_policy_id) = jsonencode({
      listOfAllowedLocations = { value = var.allowed_locations }
    })
  } : {}

  # Built-in DeployIfNotExists policies that require a Log Analytics workspace
  # resource ID. These parameters have no default value in the definition, so
  # the assignment MUST supply them or Azure rejects it (MissingPolicyParameter).
  # Wired centrally to var.log_analytics_workspace_id (typically the hub LAW).
  log_analytics_policy_ids = [
    "2465583e-4e78-4c15-b6be-a36cbc7c8b0f", # Configure Azure Activity logs to stream to LAW
    "b4fe1a3b-0715-4c6c-a5ea-ffc33cf823cb", # Blob Services diag
    "25a70cc8-2bd4-47f1-90b6-1478e4662c96", # File Services diag
    "7bd000e3-37c7-4928-9f31-86c4b77c5c45", # Queue Services diag
    "2fb86bf3-d221-43d1-96d1-2434af34eaa0", # Table Services diag
    "567c93f7-3661-494f-a30f-0a94d9bfebf8", # API Management
    "c0d8e23a-47be-4032-961f-8b0ff3957061", # App Service
    "92012204-a7e4-4a95-bbe5-90d0d3e12735", # Application gateways
    "aec4c33f-2f2a-4fd3-91cd-24a939513c60", # Azure Cache for Redis
    "68ba9fc9-71b9-4e6f-9cf5-ecc07722324c", # Cosmos DB
    "a819f227-229d-44cb-8ad6-25becdb4451f", # Data Explorer
    "454c7d4b-c141-43f1-8c81-975ebb15a9b5", # Databricks
    "305408ed-dd5a-43b9-80c1-9eea87a176bb", # Synapse Analytics
    "f8352124-56fa-4f94-9441-425109cdc14b", # Bastions
    "415eaa04-e9db-476a-ba43-092d70ebe1e7", # Bot Services
    "fa570aa1-acca-4eea-8e5a-233cf2c5e4c2", # Caches (Redis Enterprise)
    "6a664864-e2b5-413e-b930-f11caa132f16", # Container Apps Environments
    "d111f33e-5cb3-414e-aec4-427e7d1080c9", # Data Lake Analytics
    "dfe69c56-9c12-4271-9e62-7607ab669582", # Data Lake Storage Gen1
    "a271e156-b295-4537-b01d-09675d9e7851", # Dedicated SQL pools
    "6201aeb7-2b5c-4671-8ab4-5d3ba4d77f3b", # Front Door and CDN profiles
    "a7c668bd-3327-474f-8fb5-8146e3e40e40", # Host pools
    "6b359d8f-f88d-4052-aa7c-32015963ecc1", # Key vaults
    "b88bfd90-4da5-43eb-936f-ae1481924291", # Managed HSMs
    "ae0fc3d3-c9ce-43e8-923a-a143db56d81e", # Cassandra clusters
    "064a3695-3197-4354-816b-65c7b952db9e", # Mongo clusters
    "5cfb9e8a-2f13-40bd-a527-c89bc596d299", # ML online endpoints
    "887dc342-c6bd-418b-9407-ab0e27deba36", # Synapse kusto pools
    "6567d3f3-42d0-4cfb-9606-9741ba60fa07", # SQL databases
    "8fc4ca5f-6abc-4b30-9565-0bd91ac49420", # SQL managed instances
    "0da6faeb-d6c6-4f6e-9f49-06277493270b", # Web PubSub Service
  ]
  log_analytics_parameters = var.log_analytics_workspace_id == "" ? {} : {
    for id in local.log_analytics_policy_ids : id => jsonencode({
      logAnalytics = { value = var.log_analytics_workspace_id }
    })
  }

  # "Keys should have a rotation policy" requires maximumDaysToRotate (no default).
  key_rotation_policy_id = "d8cf8476-a2ec-4916-896e-992351803c44"
  key_rotation_parameters = {
    (local.key_rotation_policy_id) = jsonencode({
      maximumDaysToRotate = { value = var.max_days_to_rotate }
    })
  }

  # Policies whose definition uses a data-plane mode (e.g. Microsoft.KeyVault.Data)
  # do not support non_compliance_message blocks.
  no_noncompliance_message_ids = [
    "d8cf8476-a2ec-4916-896e-992351803c44", # Keys rotation (Microsoft.KeyVault.Data)
  ]

  computed_parameters = merge(
    local.allowed_locations_parameters,
    local.log_analytics_parameters,
    local.key_rotation_parameters,
  )

  # User-supplied parameter overrides win over computed ones.
  effective_parameters = merge(local.computed_parameters, var.policy_parameters)

  # Flatten remediation role assignments: one per (policy, role) pair.
  remediation_roles = merge([
    for id, meta in local.identity_policies : {
      for role_id in data.azurerm_policy_definition.identity[id].role_definition_ids :
      "${id}::${basename(role_id)}" => {
        policy_id = id
        role_id   = role_id
      }
    }
  ]...)
}

# Look up the role definition IDs that each DeployIfNotExists / Modify policy
# declares, so the managed identity can be granted exactly those roles.
data "azurerm_policy_definition" "identity" {
  for_each = local.identity_policies

  name = each.key
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = local.assigned_policies

  name                 = each.key
  display_name         = substr(each.value.display, 0, 128)
  description          = "Managed via Terraform (terraform/policy). Built-in policy ${each.key}."
  subscription_id      = local.subscription_scope
  policy_definition_id = "${local.policy_definition_base}/${each.key}"
  enforce              = var.enforce
  not_scopes           = var.not_scopes

  parameters = lookup(local.effective_parameters, each.key, null)

  # Non-compliance messages are not supported for data-plane policy modes
  # (e.g. Microsoft.KeyVault.Data), so skip the block for those policies.
  dynamic "non_compliance_message" {
    for_each = contains(local.no_noncompliance_message_ids, each.key) ? [] : [1]
    content {
      content = "Non-compliant with organizational policy: ${each.value.display}"
    }
  }

  # DeployIfNotExists / Modify effects require a managed identity + location.
  dynamic "identity" {
    for_each = contains(local.identity_effects, each.value.effect) ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  location = contains(local.identity_effects, each.value.effect) ? var.assignment_location : null
}

# Grant the policy assignment's managed identity the roles it needs to remediate.
resource "azurerm_role_assignment" "remediation" {
  for_each = local.remediation_roles

  scope = local.subscription_scope
  # Normalize the role definition ID to the subscription-scoped form that Azure
  # stores, so re-plans stay idempotent (the policy definition data source
  # returns the tenant-scoped "/providers/..." form, which otherwise diffs and
  # forces a needless destroy/recreate of every remediation role assignment).
  role_definition_id = startswith(each.value.role_id, "/subscriptions/") ? each.value.role_id : "${local.subscription_scope}${each.value.role_id}"
  principal_id       = azurerm_subscription_policy_assignment.this[each.value.policy_id].identity[0].principal_id

  # The identity is created moments earlier; skip the AAD propagation check.
  skip_service_principal_aad_check = true
}
