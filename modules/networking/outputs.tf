output "vnet_id" {
  value = azurerm_virtual_network.vnet_mumbai.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet_mumbai.name
}

output "nsg_public_id" {
  value = azurerm_network_security_group.nsg_public.id
}

output "nsg_private_id" {
  value = azurerm_network_security_group.nsg_private.id
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.nat_mumbai.id
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.pip_nat_mumbai.ip_address
}
