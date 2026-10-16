#!/usr/bin/env bash
###############################################################################
# 変更されたスタック × 環境だけを deployments.yml から抽出し、JSON で出力する。
#
# 使い方: select-deployments.sh <git の diff 範囲> [all]
#   例) PR  : select-deployments.sh "<base>...<head>"
#       push: select-deployments.sh "<before>..<sha>"
#   第2引数に all を渡す、または範囲が不正な場合は全件を出力する（安全側）。
#
# 抽出ルール（変更の局所性）:
#   stacks/<stack>/envs/<env>/**  -> その スタック × 環境 のみ
#   stacks/<stack>/** (上記以外)   -> そのスタックの全環境
#   deployments.yml / modules/** / CI/CD の共通部品 -> 全件
#   上記以外（docs 等）            -> 対象なし（[]）
#
# 標準出力は JSON のみ。ログは標準エラーへ出す。
###############################################################################
set -euo pipefail

range="${1:-}"
force_all="${2:-}"

all=$(yq -o=json -I=0 '.deployments' deployments.yml)

emit_all() {
  echo "::notice::全スタックを対象にします（$1）" >&2
  jq -c 'sort_by(.order)' <<<"$all"
  exit 0
}

[ "$force_all" = "all" ] && emit_all "全件指定"
[ -z "$range" ] && emit_all "差分範囲が未指定"
[[ "$range" =~ ^0{40}[.] ]] && emit_all "初回 push"

if ! changed=$(git diff --name-only "$range" 2>/dev/null); then
  emit_all "差分範囲を解決できない"
fi

echo "変更ファイル:" >&2
echo "$changed" | sed 's/^/  /' >&2

# 共通部品が変わった場合は影響範囲を特定できないため全件
if grep -Eq '^(deployments\.yml|modules/|\.github/(workflows/(ci|cd|_terraform-apply)\.yml|actions/|scripts/))' <<<"$changed"; then
  emit_all "共通部品の変更"
fi

sel='[]'
while IFS= read -r f; do
  if [[ "$f" =~ ^stacks/([^/]+)/envs/([^/]+)/ ]]; then
    s="${BASH_REMATCH[1]}"; e="${BASH_REMATCH[2]}"
  elif [[ "$f" =~ ^stacks/([^/]+)/ ]]; then
    s="${BASH_REMATCH[1]}"; e="*"
  else
    continue
  fi
  sel=$(jq -c --arg s "$s" --arg e "$e" '. + [{stack:$s,env:$e}]' <<<"$sel")
done <<<"$changed"

result=$(jq -c --argjson sel "$sel" '
  [ .[] | . as $d
    | select($sel | any(.stack == $d.stack and (.env == "*" or .env == $d.env))) ]
  | sort_by(.order)' <<<"$all")

echo "対象: $result" >&2
echo "$result"
