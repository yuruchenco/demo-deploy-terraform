# terraform / required_providers / backend の定義は versions.tf を参照。

provider "azurerm" {
  # subscription_id は指定しない。環境変数 ARM_SUBSCRIPTION_ID（CI では GitHub Environment の変数）
  # から取得する。23-dmz の Environment には DMZ サブスクリプションの ID を設定する。
  #
  # DMZ 用 SP は DMZ サブスクリプション（本検証では DMZ 用 RG）にしか書き込み権限を持たない。
  # リソースプロバイダーの自動登録はサブスクリプションスコープの権限を要するため無効化し、
  # 必要なプロバイダーはサブスクリプション準備時に登録しておく。
  resource_provider_registrations = "none"

  features {}
}
