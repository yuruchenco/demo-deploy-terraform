terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }
  }

  # Remote state backend (partial config supplied at init via -backend-config).
  #
  # 環境ごとの接続先は envs/<env>/backend.hcl で与える。
  #   terraform init -reconfigure -input=false -backend-config=envs/<env>/backend.hcl
  #
  # -reconfigure は必須。付け忘れると別環境の state を
  # コピーしてしまう事故につながる。
  #
  # shared key 認証はポリシーで無効化されているため use_azuread_auth = true が必須。
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
  }
}
