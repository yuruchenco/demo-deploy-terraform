# modules

リポジトリ内ローカルモジュールを置くディレクトリです（03_State管理設計 案 A の構成）。

## 方針：原則として Azure Verified Modules (AVM) を使う

本リポジトリでは、リソース単位の実装は **AVM のレジストリモジュール**を使用します。

```hcl
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"
}
```

独自モジュールを増やすほど、Microsoft 側のベストプラクティス更新を
取り込むコストが自前のメンテナンス負債になります。
`modules/` は **AVM で表現できないものだけ**を置く場所です。

## ここに置いてよいもの

| 置くもの | 例 |
|---|---|
| AVM に存在しないリソースのラッパー | VNet Gateway（AVM 未提供のため 22-gateway では azurerm ネイティブを直書き） |
| 複数 AVM を束ねた組織固有のパターン | 「Spoke VNet + Route Table + NSG + Peering」を 1 単位で払い出す vending モジュール |
| 組織固有の命名・タグ規約の実装 | CAF 命名サフィックスの生成 |

## ここに置いてはいけないもの

- **ルートモジュール（State を持つもの）** — `stacks/` に置きます。
  `modules/` 配下に `backend` 宣言や `provider` 宣言を書かないでください。
- **環境ごとの差分** — 環境差分は `stacks/<stack>/envs/<env>/terraform.tfvars`
  で表現します。モジュールを環境ごとに分けてはいけません。
- **1 箇所からしか呼ばれない抽象化** — 再利用されないモジュールは
  可読性を下げるだけです。2 箇所目の呼び出しが発生してから切り出してください。

## 規約

- `provider` ブロックを書かない（ルートモジュールから継承する）。
  モジュール内で `provider` を宣言すると、そのモジュールを使う構成を
  `terraform destroy` できなくなる場合があります。
- 変数には必ず `description` と `type` を付ける。
- `count` / `for_each` の条件には **plan 時点で確定する値**だけを使う
  （未確定値を使うと `Invalid for_each argument` で plan が失敗します）。
- モジュール単位で README.md を置き、入力・出力・前提権限を明記する。

## 参照方法

```hcl
module "spoke" {
  source = "../../modules/spoke-vending"
  # ...
}
```

ローカルパス参照のためバージョン固定はできません。
破壊的変更を入れる場合は、全呼び出し元を同一 PR で更新してください。
