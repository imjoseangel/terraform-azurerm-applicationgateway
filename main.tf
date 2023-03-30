#-------------------------------
# Local Declarations
#-------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp[*].name, azurerm_resource_group.rg[*].name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp[*].location, azurerm_resource_group.rg[*].location, [""]), 0)
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  #ts:skip=AC_AZURE_0389 RSG lock should be skipped for now.
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags, )
}

#---------------------------------------------------------
# Public IP Creation or selection
#---------------------------------------------------------

resource "azurerm_public_ip" "main" {
  name                = lower(var.pip_name)
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#---------------------------------------------------------
# Application Gateway Creation or selection
#---------------------------------------------------------

resource "azurerm_application_gateway" "main" {
  name                = lower(var.name)
  location            = local.location
  resource_group_name = local.resource_group_name

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.vnet_subnet_id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendipcfg"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  backend_address_pool {
    name = "defaultaddresspool"
  }

  backend_http_settings {
    name                  = "defaulthttpsetting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "httplistener"
    frontend_ip_configuration_name = "frontendipcfg"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "requestroutingrule"
    rule_type                  = "Basic"
    http_listener_name         = "httplistener"
    backend_address_pool_name  = "defaultaddresspool"
    backend_http_settings_name = "defaulthttpsetting"
    priority                   = 10
  }

  dynamic "waf_configuration" {
    #ts:skip=AC_AZURE_0189 Enabling dynamically
    for_each = (var.waf_enabled && contains(["WAF", "WAF_v2"], var.sku)) ? [true] : []
    content {
      enabled          = var.waf_enabled
      firewall_mode    = var.waf_firewall_mode
      rule_set_type    = "OWASP"
      rule_set_version = "3.1"
    }
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool, backend_http_settings, http_listener, probe, request_routing_rule, waf_configuration, tags
    ]
  }

}
