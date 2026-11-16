###############################################################################
# 23-dmz スタック / dev 環境の backend 設定
#
# terraform init -reconfigure -input=false -backend-config=envs/dev/backend.hcl
#
# State は Hub と同じ環境別ストレージに置く（DMZ サブスクリプションには置かない）。
# DMZ 用 SP の書き込みは ABAC で 23-dmz.tfstate のみに制限する。
###############################################################################
resource_group_name  = "rg-tfstate-dev-jpe"
storage_account_name = "sttfstatettsdevjpe01"
container_name       = "tfstate"
key                  = "23-dmz.tfstate"
