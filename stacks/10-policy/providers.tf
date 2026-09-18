# terraform / required_providers / backend の定義は versions.tf を参照。

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_client_config" "current" {}
