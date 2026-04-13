variable "bastion_vm_name" {
  description = "Name of the Bastion VM"
  type        = string
}

variable "location" {
  description = "Azure region where the resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the VM will be deployed"
  type        = string
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "aks_id" {
  description = "The ID of the AKS cluster"
  type        = string
}

variable "aks_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "aks_rg_name" {
  description = "The resource group containing the AKS cluster"
  type        = string
}

variable "bastion_admin_group_object_ids" {
  description = "List of AAD group Object IDs to grant VM Administrator Login (SSH + sudo)"
  type        = list(string)
  default     = []
}

variable "bastion_admin_users" {
  description = "List of AAD user Object IDs to grant VM Administrator Login (SSH + sudo)"
  type        = list(string)
  default     = []
}
