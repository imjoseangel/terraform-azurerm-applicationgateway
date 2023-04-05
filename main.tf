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
  name                = var.pip_name
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

#---------------------------------------------------------
# Application Gateway Creation or selection
#---------------------------------------------------------

resource "azurerm_application_gateway" "main" {
  name                = var.name
  location            = local.location
  resource_group_name = local.resource_group_name

  sku {
    name     = var.sku
    tier     = var.sku
    capacity = var.sku_capacity == null && var.min_capacity == null ? 1 : null
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.vnet_subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  redirect_configuration {
    include_path         = true
    include_query_string = true
    name                 = "http-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "main-https"
  }

  frontend_ip_configuration {
    name                 = "frontend-config"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  backend_address_pool {
    fqdns        = var.fqdns
    ip_addresses = var.ip_addresses
    name         = "nginx-internal-pool"
  }

  backend_http_settings {
    affinity_cookie_name                = "ApplicationGatewayAffinity"
    cookie_based_affinity               = "Disabled"
    name                                = "backend-https"
    pick_host_name_from_backend_address = true
    port                                = 443
    probe_name                          = "kubernetes-health"
    protocol                            = "Https"
    request_timeout                     = 20
  }

  http_listener {
    name                           = "main-http"
    frontend_ip_configuration_name = "frontend-config"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  ssl_certificate {
    key_vault_secret_id = var.key_vault_secret_id
    name                = var.ssl_certificate_name
  }

  http_listener {
    name                           = "main-https"
    frontend_ip_configuration_name = "frontend-config"
    frontend_port_name             = "port_443"
    host_names                     = var.host_names
    protocol                       = "Https"
    ssl_certificate_name           = var.ssl_certificate_name
  }

  request_routing_rule {
    http_listener_name          = "main-http"
    name                        = "http-redirect"
    priority                    = 10
    redirect_configuration_name = "http-redirect"
    rule_type                   = "Basic"
  }

  request_routing_rule {
    backend_address_pool_name  = "nginx-internal-pool"
    backend_http_settings_name = "backend-https"
    http_listener_name         = "main-https"
    name                       = "kubernetes-ingress"
    priority                   = 20
    rewrite_rule_set_name      = "x-forward-for"
    rule_type                  = "Basic"
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

  dynamic "autoscale_configuration" {
    for_each = var.min_capacity == null ? [] : [true]
    content {
      max_capacity = var.max_capacity
      min_capacity = var.min_capacity
    }
  }

  identity {
    type         = var.identity_type
    identity_ids = var.user_assigned_identity_id
  }

  rewrite_rule_set {
    name = "x-forward-for"

    rewrite_rule {
      name          = "x-forward-for"
      rule_sequence = 100

      request_header_configuration {
        header_name  = "X-Forwarded-For"
        header_value = "{var_add_x_forwarded_for_proxy}"
      }
    }
  }

  probe {
    interval                                  = 30
    minimum_servers                           = 0
    name                                      = "kubernetes-health"
    path                                      = "/"
    pick_host_name_from_backend_http_settings = true
    protocol                                  = "Https"
    timeout                                   = 30
    unhealthy_threshold                       = 3

    match {
      status_code = [
        "200-399",
      ]
    }
  }

  # lifecycle {
  #   ignore_changes = [
  #     backend_address_pool, backend_http_settings, http_listener, probe, request_routing_rule, waf_configuration, tags
  #   ]
  # }

}
