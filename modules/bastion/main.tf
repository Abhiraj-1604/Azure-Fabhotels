resource "tls_private_key" "bastion_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "${var.bastion_vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.bastion_vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id,
  ]

  identity {
    type = "SystemAssigned"
  }


  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.bastion_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/custom_data.sh.tpl", {
    rg_name  = var.aks_rg_name
    aks_name = var.aks_name
  }))
}

resource "azurerm_role_assignment" "bastion_aks_user" {
  scope                = var.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_linux_virtual_machine.bastion.identity[0].principal_id
}

# AAD SSH Login is installed directly via cloud-init (aadsshlogin package)
# to avoid a race condition with the VM extension fighting cloud-init for the dpkg lock.

# Grant the AAD admin group "Virtual Machine Administrator Login" (SSH + sudo)
resource "azurerm_role_assignment" "bastion_vm_admin_group" {
  count                            = length(var.bastion_admin_group_object_ids)
  scope                            = azurerm_linux_virtual_machine.bastion.id
  role_definition_name             = "Virtual Machine Administrator Login"
  principal_id                     = var.bastion_admin_group_object_ids[count.index]
  skip_service_principal_aad_check = true
}

# Grant individual users "Virtual Machine Administrator Login" (SSH + sudo)
resource "azurerm_role_assignment" "bastion_vm_admin_users" {
  count                = length(var.bastion_admin_users)
  scope                = azurerm_linux_virtual_machine.bastion.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.bastion_admin_users[count.index]
}
