###############################################################################
# 20-connectivity スタック / prod 環境の backend 設定
#
# terraform init -reconfigure -input=false -backend-config=envs/prod/backend.hcl
#
# 拡張子が .hcl なのは envs/<env>/*.tfvars を -var-file に
# 一括で渡す運用と衝突させないため（自動読み込みもされない）。
# State は「スタック × 環境」で必ず分離する。
###############################################################################
resource_group_name  = "rg-tfstate-prod-jpe"
storage_account_name = "sttfstatettsprodjpe01"
container_name       = "tfstate"
key                  = "20-connectivity.tfstate"
