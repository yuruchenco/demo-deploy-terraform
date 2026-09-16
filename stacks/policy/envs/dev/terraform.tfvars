###############################################################################
# policy stack / dev
#
# 適用: terraform plan -var-file=envs/dev/terraform.tfvars
###############################################################################
subscription_id     = "7b0d56d6-0b9c-4ec4-82bb-98232df5db5b"
assignment_location = "japaneast"

# 既定は false（DoNotEnforce）。まず影響を観測し、
# 問題がないことを確認してから環境ごとに true へ切り替える。
enforce = false

# 中央 Log Analytics ワークスペースの resource ID。
# platform スタックで deploy_log_analytics = true にした後、
# その output をここへ設定する。空のままだと
# DeployIfNotExists 系ポリシーは除外が必要になる。
log_analytics_workspace_id = ""

excluded_policies = []
not_scopes        = []
allowed_locations = []
