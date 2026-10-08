# 00-management-groups

Management Group 階層（02_スタック構成 #1）。

| 項目 | 値 |
|---|---|
| 含めるリソース | Management Group 階層 / サブスクリプション関連付け |
| 変更頻度 | 低 |
| 影響範囲 | 全社（テナント） |
| 対象環境 | **stg / prd のみ**（dev なし） |
| 依存元スタック | — |
| State キー | `00-management-groups.tfstate` |

## dev が存在しない理由

テナント単位のリソースであり、Sandbox テナントに同じ階層を作っても
検証にならないためです（02_スタック構成 #1）。
`variables.tf` の `environment` にも `stg` / `prd` のみを許可する validation を入れ、
誤って dev 用の tfvars を作れないようにしています。

## 階層の表現方法

`azurerm_management_group` の `for_each` は**自分自身の他インスタンスを参照できません**
（参照グラフが循環するため）。そのため階層を 3 つのリソースに分けて宣言しています。

```
tenant root (Terraform 管理外)
└── azurerm_management_group.intermediate_root     mg-<org>-<env>
    └── azurerm_management_group.level1            mg-<org>-<env>-<key>
        └── azurerm_management_group.level2        mg-<org>-<env>-<key>
```

ALZ の標準階層（Platform / Landing Zones / Sandbox / Decommissioned と
その配下の Identity / Management / Connectivity / Corp / Online）は
レベル2 までで表現できます。

## 必要な権限

tenant root スコープの **Management Group Contributor**（または Owner）が必要です。
既定では `deploy_management_groups = false` としているため、
権限が付与されるまでは plan は通っても何も作られません。

> Entra ID の全体管理者であっても、既定では tenant root 管理グループへの
> アクセス権を持ちません。Azure portal の「アクセス管理」から
> 昇格（elevate access）したうえでロールを割り当ててください。

## 下流スタックへの値の渡し方

`terraform_remote_state` で暗黙参照させず、`terraform output` した値を
下流スタックの `envs/<env>/terraform.tfvars` へ**手動で転記**します。
plan 時点で値が未確定になり `for_each` / `count` が壊れるのを避けるためです
（40-management と同じ方針）。

```bash
terraform output -json level2_management_group_ids
```

## 運用上の注意

- `intermediate_root` には `prevent_destroy = true` を設定しています。
  階層全体の土台であり、誤削除の影響が全社に及ぶためです。
- `deploy_management_groups` を運用開始後に `false` へ戻してはいけません。
  配下にサブスクリプションがある管理グループは削除できないため、
  apply が途中で失敗し中途半端な状態になります。
- `subscription_associations` からエントリを削除すると、当該サブスクリプションは
  テナントルート直下へ戻り、**配下の Policy 割り当てが一斉に外れます**。
  削除は destroy 相当の影響を持つ操作として扱ってください。

## 実行

```bash
cd stacks/00-management-groups
terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
terraform plan -var-file=envs/stg/terraform.tfvars -out=tfplan
terraform apply tfplan
```
