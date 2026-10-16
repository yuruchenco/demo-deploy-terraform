###############################################################################
# 40-management スタック / stg（検証）
###############################################################################
subscription_id = "ed77507d-7fd3-4aed-b04c-982b8f58a381"
environment     = "stg"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

deploy_log_analytics         = false
log_analytics_retention_days = 30

deploy_key_vault           = false
key_vault_purge_protection = true
key_vault_soft_delete_days = 90

tags = {
  CostCenter  = "ccoe"
  Criticality = "medium"
}
