###############################################################################
# policy stack / dev backend
#
# terraform init -reconfigure -input=false -backend-config=envs/dev/backend.hcl
###############################################################################
resource_group_name  = "rg-tfstate-cicd-demo"
storage_account_name = "sttfstatecicddemo01"
container_name       = "tfstate"
key                  = "policy/dev.tfstate"
