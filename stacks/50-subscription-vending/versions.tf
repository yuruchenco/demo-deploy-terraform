terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }
  }

  # ???? 1 ? = 1 State????? envs/<env>/<subscription_name>/backend.hcl ?????
  #   terraform init -reconfigure -input=false -backend-config=envs/<env>/<subscription_name>/backend.hcl
  # key ? "50-subscription-vending/<subscription_name>.tfstate"?check-env-consistency.sh ?????
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
    snapshot         = true
  }
}
