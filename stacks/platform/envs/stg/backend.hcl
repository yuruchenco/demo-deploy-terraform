###############################################################################
# platform stack / stg backend
#
# terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
###############################################################################
resource_group_name  = "rg-tfstate-cicd-demo"
storage_account_name = "sttfstatecicddemo01"
container_name       = "tfstate"
key                  = "platform/stg.tfstate"
