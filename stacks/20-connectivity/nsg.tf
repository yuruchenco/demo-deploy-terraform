###############################################################################
# サブネット NSG
#
# 背景:
#   プラットフォーム側の Azure Policy（本テナントではルート管理グループの
#   MCAPSGovDeployPolicies）が DeployIfNotExists で、NSG の付いていない
#   サブネットに NSG を自動付与する。
#
#   IaC 側で NSG を指定していないと、
#     1. Terraform がサブネットを NSG なしで作成
#     2. Policy が NSG を作成して付与
#     3. 次の plan で「NSG を外す」差分が出る
#     4. apply すると Policy が再付与する
#   という是正ループになる。実際に本リポジトリで発生した。
#
# 方針:
#   IaC 側で先に NSG を定義して付与する。付与済みであれば
#   DeployIfNotExists の条件を満たすため、Policy は発火しない。
#   「プラットフォームが補完する属性は IaC 側で明示的に宣言する」
#   という原則の具体例。
#
# 対象外のサブネット:
#   AzureFirewallSubnet は NSG を付けられない（Azure の制約）。
#   GatewaySubnet は NSG 非推奨のため付けない。
#   いずれも Policy 側でも除外されている。
###############################################################################

locals {
  # Azure Bastion に必要な NSG ルール。
  # 1 つでも欠けると Bastion のプロビジョニングまたは接続が失敗する。
  # https://learn.microsoft.com/azure/bastion/bastion-nsg
  bastion_security_rules = {
    AllowHttpsInbound = {
      name                       = "AllowHttpsInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
    AllowGatewayManagerInbound = {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    }
    AllowAzureLoadBalancerInbound = {
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
    AllowBastionHostCommunicationInbound = {
      name                       = "AllowBastionHostCommunication"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowSshRdpOutbound = {
      name                       = "AllowSshRdpOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowAzureCloudOutbound = {
      name                       = "AllowAzureCloudOutbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    }
    AllowBastionCommunicationOutbound = {
      name                       = "AllowBastionCommunication"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    AllowGetSessionInformationOutbound = {
      name                       = "AllowGetSessionInformation"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  }
}

module "nsg_bastion" {
  count = var.deploy_subnet_nsgs ? 1 : 0

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-bas-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  security_rules      = local.bastion_security_rules
  tags                = local.tags
}

# DNS Private Resolver 用サブネットは委任済みで、
# 追加のルールは不要。既定の NSG ルールのみで動作する。
# Policy の DeployIfNotExists を発火させないことが目的。
module "nsg_dnsresolver_inbound" {
  count = var.deploy_subnet_nsgs ? 1 : 0

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-dnsin-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}

module "nsg_dnsresolver_outbound" {
  count = var.deploy_subnet_nsgs ? 1 : 0

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-dnsout-${local.suffix}"
  resource_group_name = module.rg.name
  location            = var.location
  tags                = local.tags
}
