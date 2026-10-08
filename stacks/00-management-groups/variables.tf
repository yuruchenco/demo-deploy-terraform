###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = <<-EOT
    azurerm プロバイダーの認証コンテキストに使用するサブスクリプション ID。

    管理グループはテナントスコープのリソースのため、ここで指定した
    サブスクリプションにリソースが作成されるわけではない。
    プロバイダーの初期化に必要なだけである。
  EOT
}

variable "org" {
  type        = string
  description = "Organization prefix used in management group naming (e.g. mg-<org>-<env>)."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。"

  validation {
    # 02_スタック構成 #00-management-groups のとおり dev は対象外。
    # テナント単位のリソースであり、Sandbox テナントには階層を作らない。
    condition     = contains(["stg", "prd"], var.environment)
    error_message = "environment must be one of: stg, prd. 00-management-groups は dev を持たない（02_スタック構成 #1）。"
  }
}

###############################################################################
# Feature flags
#
# 規約 (06_フィーチャーフラグ規約): すべての deploy_* / enable_* は
# default = false（安全側）とする。各環境は envs/<env>/terraform.tfvars で
# 必要なものだけ true にオプトインする。
###############################################################################
variable "deploy_management_groups" {
  type        = bool
  description = <<-EOT
    管理グループ階層をデプロイするかどうか。

    【注意】false へ戻すと階層全体が destroy 対象になる。
    配下にサブスクリプションが存在する管理グループは削除できないため、
    実際には apply が失敗して中途半端な状態になる。
    運用開始後に false へ戻してはならない。
  EOT
  default     = false
}

###############################################################################
# 階層定義
#
# azurerm_management_group の for_each は自分自身の他インスタンスを
# 参照できない（参照グラフが循環するため）。
# そのため階層を「中間ルート → レベル1 → レベル2」の 3 リソースに分けて宣言する。
# ALZ の標準階層はレベル2 までで表現できる。
###############################################################################
variable "intermediate_root_display_name" {
  type        = string
  description = "中間ルート管理グループの表示名。"
  default     = "Platform Root"
}

variable "level1_management_groups" {
  type = map(object({
    display_name = string
  }))
  description = <<-EOT
    中間ルート直下の管理グループ。キーが管理グループ名（ID）のサフィックスになる。

    例:
      {
        platform      = { display_name = "Platform" }
        landingzones  = { display_name = "Landing Zones" }
        sandbox       = { display_name = "Sandbox" }
        decommissioned = { display_name = "Decommissioned" }
      }
  EOT
  default     = {}
}

variable "level2_management_groups" {
  type = map(object({
    display_name = string
    parent_key   = string
  }))
  description = <<-EOT
    レベル1 配下の管理グループ。parent_key は level1_management_groups のキーを指す。

    例:
      {
        identity     = { display_name = "Identity",     parent_key = "platform" }
        management   = { display_name = "Management",   parent_key = "platform" }
        connectivity = { display_name = "Connectivity", parent_key = "platform" }
        corp         = { display_name = "Corp",         parent_key = "landingzones" }
        online       = { display_name = "Online",       parent_key = "landingzones" }
      }
  EOT
  default     = {}

  validation {
    condition     = alltrue([for v in var.level2_management_groups : length(trimspace(v.parent_key)) > 0])
    error_message = "level2_management_groups の parent_key は必須。level1_management_groups のキーを指定すること。"
  }
}

###############################################################################
# サブスクリプションの関連付け
#
# サブスクリプションの移動は「どの Policy が効くか」を変える操作であり、
# 影響範囲が大きい。明示的に列挙したものだけを管理対象とする。
###############################################################################
variable "subscription_associations" {
  type = map(object({
    management_group_key  = string
    management_group_tier = optional(string, "level2")
    subscription_id       = string
  }))
  description = <<-EOT
    管理グループへ関連付けるサブスクリプション。

    management_group_tier は "root" / "level1" / "level2" のいずれか。
    どの変数で定義した管理グループを指すかを示す。

    例:
      {
        connectivity-prd = {
          management_group_key = "connectivity"
          subscription_id      = "00000000-0000-0000-0000-000000000000"
        }
      }
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for v in var.subscription_associations :
      contains(["root", "level1", "level2"], v.management_group_tier)
    ])
    error_message = "management_group_tier must be one of: root, level1, level2."
  }
}
