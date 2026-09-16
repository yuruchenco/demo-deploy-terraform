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
  #
  # 環境ごとの接続先は envs/<env>/backend.hcl で与える。
  #   terraform init -reconfigure -input=false -backend-config=envs/<env>/backend.hcl
  #
  # -reconfigure は必須。付け忘れると Terraform が
  # "Do you want to copy existing state to the new backend?" を尋ね、
  # 誤って yes と答えると dev の state が prd を上書きする事故になる。
  #
  # 拡張子を .hcl にしているのは、envs/<env>/*.tfvars を
  # まとめて -var-file に渡す運用と衝突させないため。
  #
  # NOTE: 本テナントではポリシーによりストレージアカウントの
  # publicNetworkAccess が強制的に Disabled にされるため、state 用
  # ストレージへは Private Endpoint 経由でしか到達できない。
  # したがって GitHub-hosted runner からはこの backend を利用できず、
  # self-hosted runner もしくは Azure Private Networking 対応の
  # larger runner が必要になる。
  # shared key 認証も無効化されているため use_azuread_auth = true が必須。
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
    # resource_group_name / storage_account_name / container_name / key
    # は envs/<env>/backend.hcl から供給する。
  }
}
