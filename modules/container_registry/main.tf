resource "azurerm_container_registry" "acr" {
  name                          = var.acr_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  public_network_access_enabled = true
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}
