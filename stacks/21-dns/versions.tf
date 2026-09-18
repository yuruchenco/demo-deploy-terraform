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
  # 誤って yes と答えると dev の state が prod を上書きする事故になる。
  # -migrate-state は使用禁止。
  #
  # 拡張子を .hcl にしているのは、envs/<env>/*.tfvars を
  # まとめて -var-file に渡す運用と衝突させないため。
  #
  # NOTE: 本テナントではポリシーによりストレージアカウントの
  # publicNetworkAccess が強制的に Disabled にされる。
  # 本検証では Network Security Perimeter (NSP) を Enforced モードで
  # 関連付け、Inbound アクセスルールに送信元グローバル IP を登録することで、
  # publicNetworkAccess = Disabled のままデータプレーンへ到達させている。
  # shared key 認証も無効化されているため use_azuread_auth = true が必須。
  backend "azurerm" {
    use_azuread_auth = true
    use_oidc         = true
    snapshot         = true
    # resource_group_name / storage_account_name / container_name / key
    # は envs/<env>/backend.hcl から供給する。
  }
}
