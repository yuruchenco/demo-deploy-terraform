###############################################################################
# policy stack / prd
#
# 適用: terraform plan -var-file=envs/prd/terraform.tfvars
###############################################################################
subscription_id     = "0a33aa1b-d8ef-429b-926d-da98db87b7cb"
assignment_location = "japaneast"

# 既定は false（DoNotEnforce）。まず影響を観測し、
# 問題がないことを確認してから環境ごとに true へ切り替える。
enforce = false

# 中央 Log Analytics ワークスペースの resource ID。
# 40-management スタックで deploy_log_analytics = true にした後、
# その output をここへ設定する。空のままだと
# DeployIfNotExists 系ポリシーは除外が必要になる。
log_analytics_workspace_id = ""

excluded_policies = []
not_scopes        = []
allowed_locations = []
