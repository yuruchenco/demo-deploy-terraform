###############################################################################
# 50-subscription-vending / dev / sub-sample-b
#
#   terraform init -reconfigure -input=false -backend-config=envs/dev/sub-sample-b/backend.hcl
#   terraform plan -var-file=envs/dev/sub-sample-b/terraform.tfvars
###############################################################################
environment       = "dev"
subscription_name = "sub-sample-b"
department        = "engineering"

tags = {
  CostCenter  = "engineering"
  Criticality = "low"
}
