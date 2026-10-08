###############################################################################
# Identity（ID 関連リソース）
#
# 02_スタック構成 #6。テナント単位のリソースでライフサイクルが異なるため、
# ネットワークや Policy とは独立した State とする。
# 依存元は 00-management-groups（カスタムロールの assignable_scopes に
# 管理グループ ID を使用する）。
#
# 【管理境界】
# Entra ID のディレクトリオブジェクト（ユーザー / グループ / アプリ登録）は
# 本スタックの管理対象外とする。Azure RBAC とは権限体系・承認者・監査要件が
# 異なり、同一 State に同居させると Azure 側の軽微な変更でも
# ディレクトリ権限を持つ SP が必要になってしまうため。
# 既存オブジェクトの object ID を tfvars へ転記して参照する。
###############################################################################

###############################################################################
# Resource Group (Identity)
###############################################################################
module "rg" {
  count = var.deploy_resource_group ? 1 : 0

  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name     = "rg-${local.suffix}"
  location = var.location
  tags     = local.tags
}

###############################################################################
# ユーザー割り当てマネージド ID
#
# Policy の DeployIfNotExists 修復など、プラットフォーム自動化の実行主体。
# システム割り当て ID ではなくユーザー割り当てにするのは、
# リソースを作り直しても principal ID が変わらず、
# ロール割り当てを再作成せずに済むため。
###############################################################################
resource "azurerm_user_assigned_identity" "this" {
  for_each = var.deploy_user_assigned_identities ? var.user_assigned_identities : {}

  name                = "id-${var.org}-${each.key}-${var.environment}-${var.location_short}"
  resource_group_name = local.resource_group_name
  location            = var.location

  tags = merge(local.tags, { Purpose = each.value.purpose })
}

###############################################################################
# カスタムロール定義
#
# 組み込みロールで最小権限を表現できない場合のみ定義する。
# assignable_scopes を管理グループにしておくと、配下の全サブスクリプションで
# 同一ロールを使い回せる（サブスクリプションごとの再定義が不要）。
###############################################################################
resource "azurerm_role_definition" "this" {
  for_each = var.deploy_custom_role_definitions ? var.custom_role_definitions : {}

  name        = each.key
  description = each.value.description
  scope       = local.default_scope

  permissions {
    actions          = each.value.actions
    not_actions      = each.value.not_actions
    data_actions     = each.value.data_actions
    not_data_actions = each.value.not_data_actions
  }

  assignable_scopes = coalesce(each.value.assignable_scopes, [local.default_scope])
}

###############################################################################
# ロール割り当て
#
# 【注意】ロール割り当ての削除は即座に権限剥奪となる。
# CI/CD 実行 SP 自身の権限を本スタックで管理する場合、
# 誤った変更で自分自身を締め出す可能性がある点に留意すること。
###############################################################################
resource "azurerm_role_assignment" "this" {
  for_each = var.deploy_role_assignments ? var.role_assignments : {}

  principal_id = each.value.principal_id
  scope        = coalesce(each.value.scope, local.default_scope)
  description  = each.value.description

  # 組み込みロールは名前で、カスタムロールは本スタックが作った定義の ID で指定する。
  # variables.tf の validation により、どちらか一方だけが非 null であることを保証している。
  role_definition_name = each.value.role_definition_name
  role_definition_id = (
    each.value.custom_role_definition_key == null
    ? null
    : azurerm_role_definition.this[each.value.custom_role_definition_key].role_definition_resource_id
  )

  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}
