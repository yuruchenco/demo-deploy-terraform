locals {
  suffix = "${var.org}-gw-${var.environment}-${var.location_short}-${var.instance}"

  # gateway_type = "None" のとき Gateway は一切作らない。
  # 条件は plan 時点で確定する入力変数のみで構成する。
  deploy_gateway = var.gateway_type != "None"

  tags = merge({
    Environment = var.environment
    Workload    = "gateway"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "22-gateway"
  }, var.tags)
}
