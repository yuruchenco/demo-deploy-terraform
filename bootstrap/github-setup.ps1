<#
.SYNOPSIS
  GitHub Environments と変数を一括作成する。

.DESCRIPTION
  OIDC（シークレットレス）で CI/CD を動かすために必要な
  Environment と Variables を作成する。Secrets は一切作成しない。

  事前に GitHub CLI の認証が必要。

      winget install --id GitHub.cli -e
      gh auth login   # Scopes: repo, workflow

  Azure 側（Entra アプリ / フェデレーション資格情報 / RBAC）は
  別途作成済みであること。詳細は README.md を参照。

.EXAMPLE
  ./bootstrap/github-setup.ps1 `
    -Repo             yuruchenco/demo-deploy-terraform `
    -TenantId         e684f651-131b-4e1a-aae7-63232c55ecb0 `
    -PlanClientId     2ca12157-f98c-4848-8f6f-153d258423fd `
    -ApplyClientId    02969592-e53b-48f5-9cb2-a036878d351d `
    -NspResourceGroup rg-nsp-dev-jpe `
    -NspName          nsp-tfstate-dev-jpe `
    -NspProfileName   prof-tfstate-dev `
    -StateStorageAccount sttfstatettsdevjpe01
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Repo,
  [Parameter(Mandatory)][string]$TenantId,
  [Parameter(Mandatory)][string]$PlanClientId,
  [Parameter(Mandatory)][string]$ApplyClientId,

  # NSP 一時許可を使わない場合（self-hosted runner など）は指定しない。
  [string]$NspResourceGroup = "",
  [string]$NspName = "",
  [string]$NspProfileName = "",
  [string]$StateStorageAccount = "",

  # CI もリモート State を使うか。false ならローカル State で plan する。
  [bool]$UseRemoteState = $true,

  # Environment を作る対象。deployments.yml の environment 列に対応する。
  [string[]]$Environments = @(
    "dev-10-policy",
    "dev-20-connectivity",
    "dev-21-dns",
    "dev-40-management"
  )
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "gh CLI が見つかりません。winget install --id GitHub.cli -e を実行してください。"
}

function Set-RepoVariable([string]$Name, [string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    Write-Host "  skip (未指定) : $Name"
    return
  }
  gh variable set $Name --repo $Repo --body $Value | Out-Null
  Write-Host "  repo var      : $Name = $Value"
}

function Set-EnvVariable([string]$EnvName, [string]$Name, [string]$Value) {
  gh variable set $Name --repo $Repo --env $EnvName --body $Value | Out-Null
  Write-Host "    env var     : $Name = $Value"
}

Write-Host "リポジトリ変数を設定します。"
# RUNNER_LABEL は必ずリポジトリレベルに置くこと。
# Environment レベルに置くと runs-on の評価時に解決されず、
# 黙って ubuntu-latest にフォールバックする。
Set-RepoVariable "ARM_TENANT_ID"        $TenantId
Set-RepoVariable "USE_REMOTE_STATE"     ($UseRemoteState.ToString().ToLower())
Set-RepoVariable "NSP_RESOURCE_GROUP"   $NspResourceGroup
Set-RepoVariable "NSP_NAME"             $NspName
Set-RepoVariable "NSP_PROFILE_NAME"     $NspProfileName
Set-RepoVariable "STATE_STORAGE_ACCOUNT" $StateStorageAccount

Write-Host ""
Write-Host "Environment を作成します。"
foreach ($e in $Environments) {
  # apply 用（CD）と plan 用（CI）を分ける。
  # 同一 Environment にすると、PR の plan 時点で本番の承認ゲートが
  # 発火してしまい、レビュー前に承認を求められることになる。
  $pairs = @(
    @{ Name = $e;              ClientId = $ApplyClientId; Role = "apply" },
    @{ Name = "$e-plan";       ClientId = $PlanClientId;  Role = "plan"  }
  )
  foreach ($p in $pairs) {
    gh api --silent --method PUT "repos/$Repo/environments/$($p.Name)" | Out-Null
    Write-Host "  environment   : $($p.Name)  ($($p.Role))"
    Set-EnvVariable $p.Name "ARM_CLIENT_ID" $p.ClientId
  }
}

Write-Host ""
Write-Host "完了しました。"
Write-Host ""
Write-Host "残りの手動作業:"
Write-Host "  - prd の Environment に Required reviewers を設定する（本番反映の手動承認ゲート）"
Write-Host "    Settings > Environments > prd-* > Required reviewers"
Write-Host "  - main ブランチに Branch protection と CODEOWNERS レビューを設定する"
