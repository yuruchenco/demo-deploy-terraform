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

  # Remote state backend. Configure via `terraform init -backend-config=backend.hcl`
  # or uncomment and fill in the values below.
  # backend "azurerm" {
  #   resource_group_name  = "rg-masuda-tfstate-prod-jpe-001"
  #   storage_account_name = "stmasudatfstateprodjpe"
  #   container_name       = "tfstate"
  #   key                  = "hub/connectivity.tfstate"
  #   use_oidc             = true
  # }
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
