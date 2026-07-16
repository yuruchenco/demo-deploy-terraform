terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state backend (partial config supplied at init via -backend-config).
  # NOTE: In this policy-governed tenant, storage accounts have public network
  # access disabled by policy, so the state storage account requires a Private
  # Endpoint and the runner (self-hosted, inside the Hub VNet) must resolve it
  # via Private DNS. use_azuread_auth is required because shared-key auth is
  # also disabled by policy.
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
    # resource_group_name / storage_account_name / container_name / key
    # are supplied at `terraform init -backend-config=...`.
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  # Authenticate with OIDC in CI (GitHub Actions) or `az login` locally.
  # use_oidc = true
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

data "azurerm_client_config" "current" {}
