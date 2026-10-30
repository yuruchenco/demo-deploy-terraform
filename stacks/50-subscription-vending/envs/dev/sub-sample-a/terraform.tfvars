###############################################################################
# 50-subscription-vending / dev / sub-sample-a
#
#   terraform init -reconfigure -input=false -backend-config=envs/dev/sub-sample-a/backend.hcl
#   terraform plan -var-file=envs/dev/sub-sample-a/terraform.tfvars
###############################################################################
environment       = "dev"
subscription_name = "sub-sample-a"
department        = "sales"

tags = {
  CostCenter  = "sales"
  Criticality = "low"
}
