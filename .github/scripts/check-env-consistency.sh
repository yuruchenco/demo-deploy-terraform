#!/usr/bin/env bash
###############################################################################
# 環境取り違え防止チェック（10_命名規則 / 15_Environment設計）
#
# envs/<env>/ 配下のファイル内容が、ディレクトリ名の <env> と一致しているかを検査する。
#   1. terraform.tfvars の environment = "<env>"
#   2. backend.hcl の resource_group_name / storage_account_name に <env> を含む
#   3. backend.hcl の key = "<stack>.tfstate"
#   4. (第3引数指定時) GitHub Environment 変数 STATE_STORAGE_ACCOUNT と
#      backend.hcl の storage_account_name が一致する
#
# 使い方:
#   check-env-consistency.sh                      全スタック × 全環境を検査（CI）
#   check-env-consistency.sh <stack> <env> [sa]   1 件を検査（plan 直前）
#
# variable "environment" の validation は値の範囲（dev/stg/prd）しか保証できず、
# 「stg の tfvars に dev と書く」「stg の Environment から dev の State を触る」
# といった取り違えは検出できないため、本スクリプトで補完する。
###############################################################################
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
errors=0

get() { # <file> <key>
  sed -nE "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\"([^\"]*)\".*/\1/p" "$1" | head -n1
}

err() { echo "::error file=$1::$2"; errors=$((errors + 1)); }

check_one() { # <stack> <env> [state_sa]
  local stack="$1" env="$2" sa="${3:-}"
  local dir="stacks/${stack}/envs/${env}"
  local tfvars="${root}/${dir}/terraform.tfvars" backend="${root}/${dir}/backend.hcl"

  if [ ! -f "$tfvars" ]; then err "$dir" "terraform.tfvars がありません"; return; fi
  local v; v="$(get "$tfvars" environment)"
  [ "$v" = "$env" ] || err "$dir/terraform.tfvars" "environment=\"$v\" がディレクトリ名 \"$env\" と一致しません"

  [ -f "$backend" ] || return 0
  local rg sa_file key
  rg="$(get "$backend" resource_group_name)"
  sa_file="$(get "$backend" storage_account_name)"
  key="$(get "$backend" key)"
  [[ "$rg" == *"-${env}-"* ]] || err "$dir/backend.hcl" "resource_group_name=\"$rg\" に \"-${env}-\" が含まれません"
  [[ "$sa_file" == *"${env}"* ]] || err "$dir/backend.hcl" "storage_account_name=\"$sa_file\" に \"${env}\" が含まれません"
  [ "$key" = "${stack}.tfstate" ] || err "$dir/backend.hcl" "key=\"$key\" が \"${stack}.tfstate\" と一致しません"
  if [ -n "$sa" ] && [ "$sa" != "$sa_file" ]; then
    err "$dir/backend.hcl" "GitHub Environment の STATE_STORAGE_ACCOUNT=\"$sa\" と backend.hcl の \"$sa_file\" が一致しません（Environment 変数の設定誤り）"
  fi
}

if [ $# -ge 2 ]; then
  check_one "$1" "$2" "${3:-}"
else
  for d in "$root"/stacks/*/envs/*/; do
    d="${d%/}"
    check_one "$(basename "$(dirname "$(dirname "$d")")")" "$(basename "$d")"
  done
fi

if [ "$errors" -gt 0 ]; then
  echo "環境取り違えチェック: ${errors} 件の不整合" >&2
  exit 1
fi
echo "環境取り違えチェック: OK"
