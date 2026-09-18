###############################################################################
# ExpressRoute / VPN Virtual Network Gateway
#
# Gateway は作成に 30-45 分かかり、変更頻度が極めて低い。
# Firewall 等と同じ State に置くと通常の変更まで待たされるため、
# 独立したスタックとして分離する (02_スタック構成 #22-gateway)。
#
# AVM に VNet Gateway のリソースモジュールが存在しないため、
# azurerm ネイティブリソースを使用する。
###############################################################################
resource "azurerm_public_ip" "gateway" {
  count = var.deploy_gateway_public_ip ? 1 : 0

  name                = "pip-vgw-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.gateway_public_ip_zones
  tags                = local.tags
}

resource "azurerm_virtual_network_gateway" "this" {
  count = local.deploy_gateway ? 1 : 0

  name                = "vgw-${local.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = var.gateway_type
  sku                 = var.gateway_sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = one(azurerm_public_ip.gateway[*].id)
    subnet_id                     = var.gateway_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}
