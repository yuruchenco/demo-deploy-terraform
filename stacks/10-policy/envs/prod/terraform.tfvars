###############################################################################
# policy stack / prod
#
# 驕ｩ逕ｨ: terraform plan -var-file=envs/prod/terraform.tfvars
###############################################################################
subscription_id     = "0a33aa1b-d8ef-429b-926d-da98db87b7cb"
assignment_location = "japaneast"

# 譌｢螳壹・ false・・oNotEnforce・峨ゅ∪縺壼ｽｱ髻ｿ繧定ｦｳ貂ｬ縺励・# 蝠城｡後′縺ｪ縺・％縺ｨ繧堤｢ｺ隱阪＠縺ｦ縺九ｉ迺ｰ蠅・＃縺ｨ縺ｫ true 縺ｸ蛻・ｊ譖ｿ縺医ｋ縲・enforce = false

# 荳ｭ螟ｮ Log Analytics 繝ｯ繝ｼ繧ｯ繧ｹ繝壹・繧ｹ縺ｮ resource ID縲・# platform 繧ｹ繧ｿ繝・け縺ｧ deploy_log_analytics = true 縺ｫ縺励◆蠕後・# 縺昴・ output 繧偵％縺薙∈險ｭ螳壹☆繧九らｩｺ縺ｮ縺ｾ縺ｾ縺縺ｨ
# DeployIfNotExists 邉ｻ繝昴Μ繧ｷ繝ｼ縺ｯ髯､螟悶′蠢・ｦ√↓縺ｪ繧九・log_analytics_workspace_id = ""

excluded_policies = []
not_scopes        = []
allowed_locations = []
