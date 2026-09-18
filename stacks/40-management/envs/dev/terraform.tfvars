###############################################################################
# 40-management スタック / dev
#
# 適用:
#   terraform init -reconfigure -input=false -backend-config=envs/dev/backend.hcl
#   terraform plan  -var-file=envs/dev/terraform.tfvars -out=tfplan
#   terraform apply tfplan
###############################################################################
subscription_id = "ed77507d-7fd3-4aed-b04c-982b8f58a381"
environment     = "dev"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

###############################################################################
# Feature flags
#
# dev で true にしたものが自動的に stg / prod へ波及することはない。
# 昇格させる場合は envs/stg, envs/prod の tfvars を明示的に変更し、
# PR の plan 差分としてレビューする。
###############################################################################
deploy_log_analytics         = true
log_analytics_retention_days = 30

deploy_key_vault           = true
key_vault_purge_protection = false
key_vault_soft_delete_days = 7

tags = {
  CostCenter  = "ccoe"
  Criticality = "low"
}
