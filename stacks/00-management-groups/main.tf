###############################################################################
# Management Group 階層
#
# 02_スタック構成 #1。全社（テナント）に影響する最上位のスタックであり、
# 変更頻度が極端に低く承認者も他スタックと異なるため、独立した State とする。
#
# 適用順序は最初（order 0）。10-policy / 30-identity / 50-subscription-vending は
# 本スタックが作る管理グループ ID を tfvars 経由で受け取る。
#
# 【参照方式】
# 下流スタックへは terraform_remote_state で暗黙参照させず、output した値を
# 各スタックの envs/<env>/terraform.tfvars へ明示的に転記する運用とする。
# plan 時点で値が未確定になり for_each / count が壊れるのを避けるため。
###############################################################################

###############################################################################
# 中間ルート管理グループ
#
# テナントルート直下に 1 つだけ作成する。
# テナントルートそのものは Terraform 管理下に置かない（削除不能かつ全社影響のため）。
###############################################################################
resource "azurerm_management_group" "intermediate_root" {
  count = var.deploy_management_groups ? 1 : 0

  name                       = local.intermediate_root_name
  display_name               = var.intermediate_root_display_name
  parent_management_group_id = local.tenant_root_id

  lifecycle {
    # 全 Spoke / 全 Policy 割り当ての土台。誤って destroy できないようにする。
    # 03_State管理設計 #17 と同じ思想。
    prevent_destroy = true
  }
}

###############################################################################
# レベル1（Platform / Landing Zones / Sandbox / Decommissioned）
###############################################################################
resource "azurerm_management_group" "level1" {
  for_each = var.deploy_management_groups ? var.level1_management_groups : {}

  name                       = "${local.intermediate_root_name}-${each.key}"
  display_name               = each.value.display_name
  parent_management_group_id = local.intermediate_root_id
}

###############################################################################
# レベル2（Identity / Management / Connectivity / Corp / Online）
#
# parent_key で参照するレベル1 が存在しない場合は plan 時にエラーとなる。
# 誤記を apply 前に検出できるよう、あえて lookup のデフォルトは設けない。
###############################################################################
resource "azurerm_management_group" "level2" {
  for_each = var.deploy_management_groups ? var.level2_management_groups : {}

  name                       = "${local.intermediate_root_name}-${each.key}"
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.level1[each.value.parent_key].id
}

###############################################################################
# サブスクリプションの関連付け
#
# 【注意】関連付けを削除すると、当該サブスクリプションはテナントルート直下へ
# 戻される。配下の Policy 割り当てが一斉に外れるため、destroy 相当の影響を持つ。
###############################################################################
resource "azurerm_management_group_subscription_association" "this" {
  for_each = var.deploy_management_groups ? var.subscription_associations : {}

  management_group_id = (
    each.value.management_group_tier == "root" ? local.intermediate_root_id :
    each.value.management_group_tier == "level1" ? azurerm_management_group.level1[each.value.management_group_key].id :
    azurerm_management_group.level2[each.value.management_group_key].id
  )
  subscription_id = "/subscriptions/${each.value.subscription_id}"
}
