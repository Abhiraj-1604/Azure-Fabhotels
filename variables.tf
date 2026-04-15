variable "location" {
  description = "Location of the application"
  type        = string
}

variable "region" {
  description = "Region of the application"
  type        = string
}

variable "environment" {
  description = "Environment of the application"
  type        = string
}

variable "project" {
  description = "project name"
  type        = string
}

variable "address_space" {
  description = "Address space of the virtual network"
  type        = list(string)
}

variable "private_subnet_address_prefixes" {
  description = "Address prefixes for the private subnet"
  type        = list(string)
}

variable "public_subnet_address_prefixes" {
  description = "Address prefixes for the public subnet"
  type        = list(string)
}

# AKS Variables

variable "aks_cluster_name" {
  type = string
}

variable "aks_dns_prefix" {
  type = string
}

variable "aks_sku_tier" {
  type = string
}

variable "aks_kubernetes_version" {
  type = string
}

variable "aks_default_node_pool_name" {
  type = string
}

variable "aks_default_vm_size" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "acr_sku" {
  type = string
}

variable "acr_zone_redundancy_enabled" {
  type = bool
}
variable "aks_default_min_count" {
  type = number
}

variable "aks_default_max_count" {
  type = number
}

variable "aks_additional_node_pools" {
  type = map(object({
    vm_size     = string
    min_count   = number
    max_count   = number
    node_labels = optional(map(string))
  }))
}

variable "aks_private_cluster_enabled" {
  type = bool
}

variable "aks_network_plugin" {
  type = string
}

variable "aks_network_plugin_mode" {
  type = string
}

variable "aks_service_cidr" {
  type = string
}

variable "aks_dns_service_ip" {
  type = string
}

variable "aks_oidc_issuer_enabled" {
  type = bool
}

variable "aks_workload_identity_enabled" {
  type = bool
}

variable "aks_azure_policy_enabled" {
  type = bool
}

variable "aks_aad_admin_group_object_ids" {
  description = "List of AAD group object IDs granted cluster-admin access (required when local_account_disabled = true)"
  type        = list(string)
  default     = []
}

variable "aks_admin_users" {
  description = "List of AAD user Object IDs to add to the Terraform-managed AKS Admins group. They get AKS RBAC Cluster Admin via the group."
  default     = []
}

# Bastion Variables
variable "bastion_vm_size" {
  description = "Size of the Bastion VM"
  type        = string
  default     = "Standard_B2s"
}

variable "bastion_admin_username" {
  description = "Admin username for the Bastion VM"
  type        = string
  default     = "azureuser"
}
