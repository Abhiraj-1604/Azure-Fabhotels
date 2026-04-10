# ============================================================
# NSG - Public Tier (for NICs exposed to internet traffic)
# ============================================================
resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsg-${var.project}-${var.environment}-${var.region}-public-1"
  location            = azurerm_resource_group.rg_project.location
  resource_group_name = azurerm_resource_group.rg_project.name

  # Allow HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH (restrict source_address_prefix to your IP in production)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
    project     = var.project
    tier        = "public"
  }
}

# ============================================================
# NSG - Private Tier (for NICs on internal/backend workloads)
# ============================================================
resource "azurerm_network_security_group" "nsg_private" {
  name                = "nsg-${var.project}-${var.environment}-${var.region}-private-1"
  location            = azurerm_resource_group.rg_project.location
  resource_group_name = azurerm_resource_group.rg_project.name

  # Allow traffic from within the VNet only
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer health probes
  security_rule {
    name                       = "AllowAzureLBInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny all other inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
    project     = var.project
    tier        = "private"
  }
}

# ============================================================
# NIC-Level Associations
# ------------------------------------------------------------
# When you create VMs with NICs, associate them like this:
#
#   resource "azurerm_network_interface_security_group_association" "web_vm_nsg" {
#     network_interface_id      = azurerm_network_interface.web_vm_nic.id
#     network_security_group_id = azurerm_network_security_group.nsg_public.id
#   }
#
#   resource "azurerm_network_interface_security_group_association" "db_vm_nsg" {
#     network_interface_id      = azurerm_network_interface.db_vm_nic.id
#     network_security_group_id = azurerm_network_security_group.nsg_private.id
#   }
# ============================================================
