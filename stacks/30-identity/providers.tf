# terraform / required_providers / backend の定義は versions.tf を参照。

provider "azurerm" {
  subscription_id = var.subscription_id
  # Authenticate with OIDC in CI (GitHub Actions) or `az login` locally.
  # use_oidc = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

data "azurerm_client_config" "current" {}
