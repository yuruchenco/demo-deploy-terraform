###############################################################################
# policy stack / prd
#
# 適用: terraform plan -var-file=envs/prd/terraform.tfvars
###############################################################################
subscription_id     = "0a33aa1b-d8ef-429b-926d-da98db87b7cb"
assignment_location = "japaneast"

# 既定�E false�E�EoNotEnforce�E�。まず影響を観測し、E# 問題がなぁE��とを確認してから環墁E��とに true へ刁E��替える、Eenforce = false

# 中央 Log Analytics ワークスペ�Eスの resource ID、E# platform スタチE��で deploy_log_analytics = true にした後、E# そ�E output をここへ設定する。空のままだと
# DeployIfNotExists 系ポリシーは除外が忁E��になる、Elog_analytics_workspace_id = ""

excluded_policies = []
not_scopes        = []
allowed_locations = []
