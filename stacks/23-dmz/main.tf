###############################################################################
# 23-dmz: DMZ サブスクリプション用スタック
#
# DMZ VNet / Application Gateway (WAF_v2) / Hub とのピアリングを管理する。
# 対象サブスクリプションは GitHub Environment の ARM_SUBSCRIPTION_ID（DMZ）で決まる。
#
# Hub とのピアリング（双方向）は本スタックだけで作成・管理する。
#   - DMZ -> Hub : DMZ VNet の子リソース
#   - Hub -> DMZ : AVM の create_reverse_peering。Hub VNet の resource ID を親に
#                  azapi で作成するため、Hub が別サブスクリプションでも provider の
#                  追加（エイリアス）は不要。必要なのは Hub VNet へのピアリング権限のみ。
# 20-connectivity（Hub）より後に適用すること。初回構築時に DMZ VNet が未作成でも、
# 本スタック内で VNet -> ピアリングの順に作成されるためエラーにならない。
###############################################################################

data "azurerm_resource_group" "dmz" {
  name = var.resource_group_name
}

module "nsg_appgw" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-agw-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.dmz.name
  location            = var.location
  security_rules      = local.appgw_security_rules
  tags                = local.tags
}

module "dmz_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = "vnet-${local.suffix}"
  location      = var.location
  parent_id     = data.azurerm_resource_group.dmz.id
  address_space = var.dmz_vnet_address_space

  subnets = {
    appgw = {
      name           = "snet-agw-${local.suffix}"
      address_prefix = var.appgw_subnet_address_prefix
      network_security_group = {
        id = module.nsg_appgw.resource_id
      }
    }
  }

  peerings = {
    hub = {
      name                               = "peer-dmz-to-${local.hub_vnet_name}"
      remote_virtual_network_resource_id = var.hub_virtual_network_id
      allow_forwarded_traffic            = true
      allow_virtual_network_access       = true

      create_reverse_peering               = true
      reverse_name                         = "peer-hub-to-vnet-${local.suffix}"
      reverse_allow_forwarded_traffic      = true
      reverse_allow_virtual_network_access = true
    }
  }

  tags = local.tags
}

###############################################################################
# Application Gateway (WAF_v2)
#
# AVM のモジュールはパラメーターが多いため、検証用に azurerm ネイティブで最小構成とする。
###############################################################################
resource "azurerm_web_application_firewall_policy" "this" {
  count = var.deploy_app_gateway ? 1 : 0

  name                = "waf-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.dmz.name
  location            = var.location

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
    }
  }

  tags = local.tags
}

resource "azurerm_public_ip" "appgw" {
  count = var.deploy_app_gateway ? 1 : 0

  name                = "pip-agw-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.dmz.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.app_gateway_zones
  tags                = local.tags

  # 検証テナントの Policy が ipTags (FirstPartyUsage) を自動付与し、ip_tags は ForceNew のため置き換えが発生する。
  lifecycle {
    ignore_changes = [ip_tags]
  }
}

resource "azurerm_application_gateway" "this" {
  count = var.deploy_app_gateway ? 1 : 0

  name                = "agw-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.dmz.name
  location            = var.location
  zones               = var.app_gateway_zones
  firewall_policy_id  = azurerm_web_application_firewall_policy.this[0].id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.app_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "gwipc"
    subnet_id = module.dmz_vnet.subnets["appgw"].resource_id
  }

  frontend_ip_configuration {
    name                 = "fe-public"
    public_ip_address_id = azurerm_public_ip.appgw[0].id
  }

  frontend_port {
    name = "fp-80"
    port = 80
  }

  backend_address_pool {
    name = "be-default"
  }

  backend_http_settings {
    name                  = "bhs-80"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "lsn-80"
    frontend_ip_configuration_name = "fe-public"
    frontend_port_name             = "fp-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rr-default"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "lsn-80"
    backend_address_pool_name  = "be-default"
    backend_http_settings_name = "bhs-80"
  }

  tags = local.tags
}

# 送信先 LAW は Hub 側サブスクリプション（40-management）にある。
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  count = var.deploy_app_gateway && local.enable_diagnostics ? 1 : 0

  name                       = "toLogAnalytics"
  target_resource_id         = azurerm_application_gateway.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
