resource "azurerm_resource_group" "rg_project" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet_mumbai" {
  name                = "vnet-${var.project}-${var.environment}"
  location            = azurerm_resource_group.rg_project.location
  resource_group_name = azurerm_resource_group.rg_project.name
  address_space       = var.address_space
  # dns_servers not set → uses Azure default DNS (168.63.129.16), which is correct for AKS
}

resource "azurerm_public_ip" "pip_nat_mumbai" {
  name                = "pip-nat-${var.project}-${var.environment}-${var.region}"
  location            = azurerm_resource_group.rg_project.location
  resource_group_name = azurerm_resource_group.rg_project.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_mumbai" {
  name                    = "nat-${var.project}-${var.environment}-${var.region}"
  location                = azurerm_resource_group.rg_project.location
  resource_group_name     = azurerm_resource_group.rg_project.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_mumbai.id
  public_ip_address_id = azurerm_public_ip.pip_nat_mumbai.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_assoc_private1" {
  subnet_id      = azurerm_subnet.snet_mumbai_private1.id
  nat_gateway_id = azurerm_nat_gateway.nat_mumbai.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_assoc_private2" {
  subnet_id      = azurerm_subnet.snet_mumbai_private2.id
  nat_gateway_id = azurerm_nat_gateway.nat_mumbai.id
}

resource "azurerm_subnet" "snet_mumbai_public1" {
  name                 = "snet-${var.project}-${var.environment}-${var.region}-public-1"
  resource_group_name  = azurerm_resource_group.rg_project.name
  virtual_network_name = azurerm_virtual_network.vnet_mumbai.name
  address_prefixes     = [var.public_subnet_address_prefixes[0]]
}

resource "azurerm_subnet" "snet_mumbai_public2" {
  name                 = "snet-${var.project}-${var.environment}-${var.region}-public-2"
  resource_group_name  = azurerm_resource_group.rg_project.name
  virtual_network_name = azurerm_virtual_network.vnet_mumbai.name
  address_prefixes     = [var.public_subnet_address_prefixes[1]]
}

resource "azurerm_subnet" "snet_mumbai_private1" {
  name                 = "snet-${var.project}-${var.environment}-${var.region}-private-1"
  resource_group_name  = azurerm_resource_group.rg_project.name
  virtual_network_name = azurerm_virtual_network.vnet_mumbai.name
  address_prefixes     = [var.private_subnet_address_prefixes[0]]
}

resource "azurerm_subnet" "snet_mumbai_private2" {
  name                 = "snet-${var.project}-${var.environment}-${var.region}-private-2"
  resource_group_name  = azurerm_resource_group.rg_project.name
  virtual_network_name = azurerm_virtual_network.vnet_mumbai.name
  address_prefixes     = [var.private_subnet_address_prefixes[1]]
}


