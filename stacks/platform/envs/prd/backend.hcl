###############################################################################
# platform stack / prd backend
#
# terraform init -reconfigure -input=false -backend-config=envs/prd/backend.hcl
#
# -reconfigure を必ず付けること。付け忘れると Terraform が
# "Do you want to copy existing state to the new backend?" を尋ね、
# 誤って yes と答えると別環境の state を上書きする事故になる。
#
# 拡張子が .tfvars でないのは意図的。envs/<env>/*.tfvars を
# まとめて -var-file に渡す運用と衝突させないため。
###############################################################################
resource_group_name  = "rg-tfstate-cicd-demo"
storage_account_name = "sttfstatecicddemo01"
container_name       = "tfstate"
key                  = "platform/prd.tfstate"
