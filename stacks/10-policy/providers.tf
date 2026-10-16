# terraform / required_providers / backend の定義は versions.tf を参照。

provider "azurerm" {
  # subscription_id は指定しない。環境変数 ARM_SUBSCRIPTION_ID（CI では GitHub Environment の変数）から取得する。
  features {}
}

data "azurerm_client_config" "current" {}
