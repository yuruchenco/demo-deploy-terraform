###############################################################################
# Core / Naming
###############################################################################
variable "subscription_id" {
  type        = string
  description = "Subscription ID of the Identity subscription."
}

variable "org" {
  type        = string
  description = "Organization prefix used in CAF naming (e.g. rg-<org>-idn-...)."
  default     = "masuda"
}

variable "environment" {
  type        = string
  description = "Environment token (dev / stg / prd). 既定値は設けない。envs/<env>/terraform.tfvars で必ず明示する。"

  validation {
    # 02_スタック構成 #6 のとおり dev は対象外。
    # テナント単位のリソースでライフサイクルが異なる。
    condition     = contains(["stg", "prd"], var.environment)
    error_message = "environment must be one of: stg, prd. 30-identity は dev を持たない（02_スタック構成 #6）。"
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region."
  default     = "japaneast"
}

variable "location_short" {
  type        = string
  description = "Short region code used in resource names (e.g. jpe for Japan East)."
  default     = "jpe"
}

variable "instance" {
  type        = string
  description = "Instance number suffix (e.g. 001)."
  default     = "001"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}

###############################################################################
# 上流スタックからの受け渡し
#
# terraform_remote_state で暗黙参照せず、00-management-groups の output を
# 本ファイルへ手動で転記する（40-management と同じ方針）。
# plan 時点で値が未確定になり for_each / count が壊れるのを避けるため。
###############################################################################
variable "platform_management_group_id" {
  type        = string
  description = <<-EOT
    カスタムロール定義と割り当ての既定スコープに使う管理グループの resource ID。

    00-management-groups の output `level1_management_group_ids["platform"]`
    もしくは `intermediate_root_id` を転記する。
    null の場合はサブスクリプションスコープへフォールバックする。
  EOT
  default     = null
}

###############################################################################
# Feature flags
#
# 規約 (06_フィーチャーフラグ規約): すべての deploy_* / enable_* は
# default = false（安全側）とする。各環境は envs/<env>/terraform.tfvars で
# 必要なものだけ true にオプトインする。
###############################################################################
variable "deploy_resource_group" {
  type        = bool
  description = "ID 関連リソースを格納するリソースグループをデプロイするかどうか。"
  default     = false
}

variable "deploy_user_assigned_identities" {
  type        = bool
  description = "プラットフォーム自動化用のユーザー割り当てマネージド ID をデプロイするかどうか。"
  default     = false
}

variable "deploy_custom_role_definitions" {
  type        = bool
  description = <<-EOT
    カスタムロール定義をデプロイするかどうか。

    【注意】ロール定義の削除は、それを参照する全ロール割り当てを無効化する。
    運用開始後に false へ戻してはならない。
  EOT
  default     = false
}

variable "deploy_role_assignments" {
  type        = bool
  description = <<-EOT
    ロール割り当てをデプロイするかどうか。

    【注意】false へ戻すと権限が一斉に剥奪される。
    CI/CD 自身の権限を本スタックで管理している場合、自分で自分を締め出すことになる。
  EOT
  default     = false
}

###############################################################################
# ユーザー割り当てマネージド ID
###############################################################################
variable "user_assigned_identities" {
  type = map(object({
    purpose = string
  }))
  description = <<-EOT
    作成するユーザー割り当てマネージド ID。キーが名前のサフィックスになる。
    purpose は Purpose タグとして付与する。

    例:
      {
        policy-remediation = { purpose = "Azure Policy DeployIfNotExists remediation" }
        aks-kubelet        = { purpose = "AKS kubelet identity" }
      }
  EOT
  default     = {}
}

###############################################################################
# カスタムロール定義
#
# 組み込みロールで表現できないものだけを定義する。
# README に記載の NSP Access Rule Operator のような
# 「特定操作のみを許可する最小権限ロール」が主な用途。
###############################################################################
variable "custom_role_definitions" {
  type = map(object({
    description = string
    actions     = list(string)

    not_actions      = optional(list(string), [])
    data_actions     = optional(list(string), [])
    not_data_actions = optional(list(string), [])

    # 未指定なら default_scope（管理グループ or サブスクリプション）を使う。
    assignable_scopes = optional(list(string), null)
  }))
  description = <<-EOT
    作成するカスタムロール定義。キーがロール名になる。

    例:
      {
        "NSP Access Rule Operator" = {
          description = "NSP のアクセスルールのみを操作できる最小権限ロール"
          actions = [
            "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/read",
            "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/write",
            "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/delete",
          ]
        }
      }
  EOT
  default     = {}
}

###############################################################################
# ロール割り当て
#
# principal_id は Entra ID のオブジェクト ID。
# Entra のグループ・アプリ自体は本スタックの管理対象外（管理境界が異なる）。
# 既に存在するオブジェクトの ID を tfvars へ転記して参照する。
###############################################################################
variable "role_assignments" {
  type = map(object({
    principal_id = string

    # 組み込みロールは role_definition_name、カスタムロールは
    # custom_role_definition_key のどちらか一方を指定する。
    role_definition_name       = optional(string, null)
    custom_role_definition_key = optional(string, null)

    # 未指定なら default_scope を使う。
    scope = optional(string, null)

    # サービスプリンシパルを割り当て対象にする場合、Entra への
    # レプリケーション遅延による PrincipalNotFound を避けるため true にする。
    skip_service_principal_aad_check = optional(bool, false)

    description = optional(string, "Managed by Terraform (30-identity)")
  }))
  description = "作成するロール割り当て。キーは任意の識別子（State のアドレスになるため変更しないこと）。"
  default     = {}

  validation {
    condition = alltrue([
      for v in var.role_assignments :
      (v.role_definition_name != null) != (v.custom_role_definition_key != null)
    ])
    error_message = "role_assignments では role_definition_name と custom_role_definition_key のどちらか一方のみを指定すること。"
  }
}
