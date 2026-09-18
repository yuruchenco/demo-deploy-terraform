locals {
  suffix = "${var.org}-dns-${var.environment}-${var.location_short}-${var.instance}"

  tags = merge({
    Environment = var.environment
    Workload    = "dns"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "21-dns"
  }, var.tags)
}
