###############################################################################
# 40-management スタック / prd（本番）
#
# purge_protection は prd では true 必須。
# 一度有効化すると無効化できないため、true→false の変更は plan で
# 「削除して再作成」になる。誤って戻さないこと。
###############################################################################
subscription_id = "<prd Management サブスクリプション ID>"
environment     = "prd"
org             = "masuda"
location        = "japaneast"
location_short  = "jpe"
instance        = "001"

deploy_log_analytics         = false
log_analytics_retention_days = 90

deploy_key_vault           = false
key_vault_purge_protection = true
key_vault_soft_delete_days = 90

tags = {
  CostCenter  = "ccoe"
  Criticality = "high"
}
