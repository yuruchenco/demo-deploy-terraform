locals {
  # テナントルート管理グループの ID は、テナント ID と同名の管理グループ。
  # 中間ルートの親として使用する。
  tenant_root_id = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"

  # 中間ルート管理グループの ID（名前）。
  # ALZ では tenant root 直下に 1 つだけ中間ルートを置き、
  # 以降の階層はすべてその配下に作る。
  intermediate_root_name = "mg-${var.org}-${var.environment}"

  # 子階層から中間ルートを参照するための resource ID。
  intermediate_root_id = one(azurerm_management_group.intermediate_root[*].id)
}
