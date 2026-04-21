resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${var.bastion_vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Console-managed rules (IP-restricted SSH, Grafana port, etc.) are owned outside Terraform
  lifecycle {
    ignore_changes = [security_rule]
  }
}

resource "azurerm_network_interface_security_group_association" "bastion_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}
