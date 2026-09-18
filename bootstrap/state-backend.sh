#!/usr/bin/env bash
###############################################################################
# Terraform State バックエンドのブートストラップ
#
# State を格納するストレージアカウント自体は Terraform では作らない。
# 「State を保存する先を作るのに State が必要」という循環を避けるため、
# 本スクリプトで Azure CLI から手動作成し、スクリプトをコミットして
# 再現性を担保する（03_State管理設計 #24）。
#
# 使い方:
#   ./bootstrap/state-backend.sh dev <subscription-id> <client-global-ip>
#
# 実行後、stacks/<stack>/envs/<env>/backend.hcl の
# storage_account_name を本スクリプトが出力した名前に合わせること。
###############################################################################
set -euo pipefail

ENV_NAME="${1:?usage: state-backend.sh <dev|stg|prd> <subscription-id> <client-ip>}"
SUBSCRIPTION_ID="${2:?subscription id required}"
CLIENT_IP="${3:?client global IP required}"

LOCATION="japaneast"
LOC_SHORT="jpe"
RG_STATE="rg-tfstate-${ENV_NAME}-${LOC_SHORT}"
RG_NSP="rg-nsp-${ENV_NAME}-${LOC_SHORT}"
SA_NAME="sttfstatetts${ENV_NAME}${LOC_SHORT}01"
CONTAINER="tfstate"
NSP_NAME="nsp-tfstate-${ENV_NAME}-${LOC_SHORT}"
NSP_PROFILE="prof-tfstate-${ENV_NAME}"

az account set --subscription "${SUBSCRIPTION_ID}"

###############################################################################
# 1. リソースグループ
###############################################################################
az group create -n "${RG_STATE}" -l "${LOCATION}" -o none
az group create -n "${RG_NSP}"   -l "${LOCATION}" -o none

###############################################################################
# 2. ストレージアカウント
#
# allow-shared-key-access false は必須。
# アクセスキー／SAS を無効化し、Entra ID 認証のみに限定する。
# backend 側は use_azuread_auth = true で対応する。
#
# publicNetworkAccess は Azure Policy により Disabled へ強制される場合がある。
# 明示指定していなくても Disabled になることを前提とする。
###############################################################################
az storage account create \
  -n "${SA_NAME}" -g "${RG_STATE}" -l "${LOCATION}" \
  --sku Standard_ZRS --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-shared-key-access false \
  --allow-blob-public-access false \
  -o none

###############################################################################
# 3. コンテナー
#
# 重要: az storage container create（データプレーン）は使わない。
# publicNetworkAccess = Disabled の環境ではデータプレーンに到達できず失敗する。
# ARM コントロールプレーン経由（az resource create）であれば
# ネットワーク制限の影響を受けずに作成できる（03_State管理設計 #25）。
###############################################################################
az resource create \
  --id "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_STATE}/providers/Microsoft.Storage/storageAccounts/${SA_NAME}/blobServices/default/containers/${CONTAINER}" \
  --properties '{}' -o none

###############################################################################
# 4. バージョニング / 論理削除
#
# State の破損・誤削除からの復旧手段。30 日保持。
###############################################################################
az storage account blob-service-properties update \
  --account-name "${SA_NAME}" -g "${RG_STATE}" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 30 \
  --enable-container-delete-retention true --container-delete-retention-days 30 \
  -o none

###############################################################################
# 5. Network Security Perimeter
#
# publicNetworkAccess = Disabled が Policy で強制される環境でも、
# NSP を Enforced モードで関連付け、Inbound アクセスルールに
# 送信元グローバル IP を登録すればデータプレーンへ到達できる。
#
# 注意: Learning モードではリソース側の publicNetworkAccess 設定が
# そのまま効くため、Disabled のままだとアクセスできない。
# Enforced にして初めて NSP のルールが評価される。
###############################################################################
az extension add --name nsp --allow-preview true --only-show-errors

az network perimeter create \
  --name "${NSP_NAME}" -g "${RG_NSP}" -l "${LOCATION}" -o none

az network perimeter profile create \
  --name "${NSP_PROFILE}" -g "${RG_NSP}" --perimeter-name "${NSP_NAME}" -o none

az network perimeter profile access-rule create \
  --name "allow-client-ip" -g "${RG_NSP}" \
  --perimeter-name "${NSP_NAME}" --profile-name "${NSP_PROFILE}" \
  --direction Inbound \
  --address-prefixes "['${CLIENT_IP}/32']" -o none

SA_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_STATE}/providers/Microsoft.Storage/storageAccounts/${SA_NAME}"
PROFILE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NSP}/providers/Microsoft.Network/networkSecurityPerimeters/${NSP_NAME}/profiles/${NSP_PROFILE}"

az network perimeter association create \
  --name "assoc-${SA_NAME}" -g "${RG_NSP}" \
  --perimeter-name "${NSP_NAME}" \
  --private-link-resource "{id:${SA_ID}}" \
  --profile "{id:${PROFILE_ID}}" \
  --access-mode Enforced -o none

###############################################################################
# 6. 誤削除防止ロック
###############################################################################
az lock create --name "lock-tfstate" --lock-type CanNotDelete \
  --resource-group "${RG_STATE}" -o none

###############################################################################
# 7. CI/CD 用の最小権限ロール（NSP アクセスルールの一時登録/削除）
#
# GitHub-hosted runner は送信元 IP が動的であり、NSP の IP 許可リストへ
# 固定登録できない。そのため実行のたびに自身の IP を登録し、終了時に削除する
# （.github/actions/nsp-runner-access）。
# その操作に必要な権限だけを NSP のリソースグループスコープで与える。
#
# self-hosted runner / larger runner へ移行した場合、このロールは不要になる。
###############################################################################
ROLE_NAME="NSP Access Rule Operator"

if ! az role definition list --name "${ROLE_NAME}" --query "[0].roleName" -o tsv | grep -q .; then
  cat > /tmp/nsp-role.json <<EOF
{
  "Name": "${ROLE_NAME}",
  "Description": "GitHub Actions runner が自身の送信元 IP を NSP の Inbound アクセスルールへ一時登録/削除するための最小権限ロール。",
  "Actions": [
    "Microsoft.Network/networkSecurityPerimeters/read",
    "Microsoft.Network/networkSecurityPerimeters/profiles/read",
    "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/read",
    "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/write",
    "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules/delete",
    "Microsoft.Resources/subscriptions/resourceGroups/read"
  ],
  "NotActions": [],
  "AssignableScopes": ["/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NSP}"]
}
EOF
  az role definition create --role-definition @/tmp/nsp-role.json -o none
  rm -f /tmp/nsp-role.json
fi

cat <<EOF

ブートストラップ完了

  resource_group_name  = "${RG_STATE}"
  storage_account_name = "${SA_NAME}"
  container_name       = "${CONTAINER}"

次の作業:
  1. 上記を stacks/*/envs/${ENV_NAME}/backend.hcl に反映する
  2. 実行主体（人 / SP）に "Storage Blob Data Contributor" を付与する
     plan 用 SP にも必須。plan は BLOB リースでロックを取得するため。
  3. CI/CD 用 SP に "${ROLE_NAME}" を ${RG_NSP} スコープで付与する

       az role assignment create \\
         --assignee-object-id <SP の objectId> \\
         --assignee-principal-type ServicePrincipal \\
         --role "${ROLE_NAME}" \\
         --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NSP}"

  4. リポジトリ変数を設定する
       NSP_NAME             = ${NSP_NAME}
       NSP_RESOURCE_GROUP   = ${RG_NSP}
       NSP_PROFILE_NAME     = ${NSP_PROFILE}
       STATE_STORAGE_ACCOUNT= ${SA_NAME}
       USE_REMOTE_STATE     = true
EOF
