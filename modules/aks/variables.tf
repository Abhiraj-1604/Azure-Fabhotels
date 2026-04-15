variable "cluster_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "dns_prefix" { type = string }
variable "sku_tier" { type = string }
variable "kubernetes_version" { type = string }
variable "default_node_pool_name" { type = string }
variable "default_vm_size" { type = string }
variable "default_min_count" { type = number }
variable "default_max_count" { type = number }
variable "vnet_subnet_id" { type = string }
variable "private_cluster_enabled" { type = bool }
variable "network_plugin" { type = string }
variable "network_plugin_mode" { type = string }
variable "service_cidr" { type = string }
variable "dns_service_ip" { type = string }

variable "additional_node_pools" {
  type = map(object({
    vm_size     = string
    min_count   = number
    max_count   = number
    node_labels = optional(map(string))
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aad_admin_group_object_ids" {
  description = "List of AAD group object IDs that will have admin access to the cluster (required when local_account_disabled = true)"
  type        = list(string)
  default     = []
}
