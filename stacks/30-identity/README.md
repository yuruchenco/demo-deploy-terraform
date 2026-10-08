# 30-identity

ID 関連リソース（02_スタック構成 #6）。

| 項目 | 値 |
|---|---|
| 含めるリソース | リソースグループ / ユーザー割り当てマネージド ID / カスタムロール定義 / ロール割り当て |
| 変更頻度 | 低 |
| 影響範囲 | 大 |
| 対象環境 | **stg / prd のみ**（dev なし） |
| 依存元スタック | `00-management-groups` |
| State キー | `30-identity.tfstate` |

## dev が存在しない理由

テナント単位のリソースでありライフサイクルが異なるためです（02_スタック構成 #6）。
`variables.tf` の `environment` にも `stg` / `prd` のみを許可する validation を入れています。

## 管理境界：Entra ID のディレクトリオブジェクトは対象外

本スタックが扱うのは **Azure RBAC** までです。
Entra ID のユーザー / グループ / アプリ登録は Terraform 管理対象に含めません。

- 権限体系が異なる（Azure RBAC = ARM、ディレクトリオブジェクト = Microsoft Graph）
- 同一 State に同居させると、Azure 側の軽微な変更でも
  ディレクトリ書き込み権限を持つ SP で apply することになり、権限が過大になる
- 承認者・監査要件も異なる

既存オブジェクトの object ID を `envs/<env>/terraform.tfvars` の
`role_assignments[].principal_id` へ転記して参照してください。

## 上流からの値の受け渡し

`terraform_remote_state` を使わず、`00-management-groups` の output を
`platform_management_group_id` へ手動で転記します（40-management と同じ方針）。

```bash
cd ../00-management-groups
terraform output -json level1_management_group_ids
```

`null` のままの場合は、カスタムロール定義とロール割り当てのスコープが
サブスクリプション（`var.subscription_id`）へフォールバックします。

## カスタムロールの用途

組み込みロールで最小権限を表現できない場合のみ定義します。
既定で用意している `NSP Access Rule Operator` は、CI の runner IP を
NSP の Inbound アクセスルールへ一時登録／削除するためだけのロールです
（リポジトリ README「State バックエンドと Network Security Perimeter」参照）。
`Network Contributor` を丸ごと与えずに済ませる目的があります。

> ロール名はテナント内で一意である必要があります。stg / prd で同じ名前を使うと
> 衝突するため、stg 側には `(stg)` サフィックスを付けています。

`assignable_scopes` を管理グループにしておくと、配下の全サブスクリプションで
同一ロールを使い回せます（サブスクリプションごとの再定義が不要）。

## 運用上の注意

- `deploy_custom_role_definitions` を `false` へ戻すと、そのロールを参照している
  **全ロール割り当てが無効化**されます。運用開始後は戻さないでください。
- `deploy_role_assignments` を `false` へ戻すと権限が一斉に剥奪されます。
  CI/CD 実行 SP 自身の権限を本スタックで管理している場合、
  **自分で自分を締め出す**ことになります。
- サービスプリンシパルを割り当て対象にする場合、Entra へのレプリケーション遅延で
  `PrincipalNotFound` になることがあります。`skip_service_principal_aad_check = true`
  を指定してください。

## 実行

```bash
cd stacks/30-identity
terraform init -reconfigure -input=false -backend-config=envs/stg/backend.hcl
terraform plan -var-file=envs/stg/terraform.tfvars -out=tfplan
terraform apply tfplan
```
