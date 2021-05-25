output "id" {
  value = azurerm_application_gateway.main.id
}

output "name" {
  value = azurerm_application_gateway.main.name
}

output "location" {
  value = azurerm_application_gateway.main.location
}

output "public_ip_id" {
  value = azurerm_public_ip.main.id
}

output "public_ip_address" {
  value = azurerm_public_ip.main.ip_address
}

output "resource_group_id" {
  value = azurerm_resource_group.rg[0].id
}
