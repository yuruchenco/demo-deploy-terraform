locals {
  # CAF-aligned naming: <type>-<org>-dmz-<env>-<region>-<instance>
  suffix = "${var.org}-dmz-${var.environment}-${var.location_short}-${var.instance}"

  hub_vnet_name = element(split("/", var.hub_virtual_network_id), 8)

  enable_diagnostics = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != ""

  tags = merge({
    Environment = var.environment
    Workload    = "dmz"
    ManagedBy   = "Terraform"
    Owner       = "CCoE"
    Stack       = "23-dmz"
  }, var.tags)

  # Application Gateway v2 に必要な NSG ルール。
  # https://learn.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups
  appgw_security_rules = {
    AllowGatewayManagerInbound = {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "65200-65535"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    }
    AllowAzureLoadBalancerInbound = {
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }
    AllowHttpInbound = {
      name                       = "AllowHttpInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}
