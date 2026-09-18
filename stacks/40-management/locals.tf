locals {
  # CAF-aligned naming: <type>-<org>-mgmt-<env>-<region>-<instance>
  suffix = "${var.org}-mgmt-${var.environment}-${var.location_short}-${var.instance}"

  tags = merge({
    Environment = var.environment
    Workload    = "management"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "40-management"
  }, var.tags)
}
