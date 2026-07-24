terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }
  }

  # Remote state backend (partial config supplied at init via -backend-config).
  # Reuse the same policy-governed backend pattern as the Hub configuration:
  # shared-key auth is disabled by policy, so Entra ID auth is required.
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
    # resource_group_name / storage_account_name / container_name / key
    # are supplied at `terraform init -backend-config=...`.
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_client_config" "current" {}
