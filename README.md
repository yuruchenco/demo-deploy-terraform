# yuichimasuda-terraform-cicd

Azure 共通基盤（ALZ 準拠 Hub-Spoke）を Terraform + Azure Verified Modules (AVM) で実装するリポジトリです。

## 構成
- [`terraform/hub/`](terraform/hub/) — Hub（Platform / Connectivity）サブスクリプションのリソース一式
  - Hub VNet / Azure Firewall + Policy / Bastion / Route Table / Private DNS Zones / DNS Private Resolver / ExpressRoute(VPN) Gateway / Log Analytics / Key Vault / DDoS(任意)
  - 詳細な手順・前提・パラメータは [`terraform/hub/README.md`](terraform/hub/README.md) を参照

## 前提
- Terraform >= 1.10
- Azure CLI (`az login`) もしくは GitHub Actions OIDC
- `terraform validate` および実 Azure に対する `terraform plan`（138 リソース）で検証済み

## CI/CD メモ
Enterprise ポリシーにより GitHub-hosted runner が無効化されているため、CI/CD ワークフローを追加する際は **self-hosted runner** を使用してください。
