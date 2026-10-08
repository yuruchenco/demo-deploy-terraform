locals {
  # CAF-aligned naming: <type>-<org>-idn-<env>-<region>-<instance>
  suffix = "${var.org}-idn-${var.environment}-${var.location_short}-${var.instance}"

  # カスタムロール定義・ロール割り当ての既定スコープ。
  # 管理グループ ID（00-management-groups の output）が与えられていればそれを使い、
  # 無ければサブスクリプションスコープへフォールバックする。
  subscription_scope = "/subscriptions/${var.subscription_id}"
  default_scope      = coalesce(var.platform_management_group_id, local.subscription_scope)

  resource_group_name = one(module.rg[*].name)

  tags = merge({
    Environment = var.environment
    Workload    = "identity"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "30-identity"
  }, var.tags)
}
