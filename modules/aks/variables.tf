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
variable "vnet_id" {
  description = "VNet ID — required for private DNS zone VNet link when private_cluster_enabled = true"
  type        = string
}
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

# ── INGRESS GATEWAY (APPLICATION GATEWAY) ────────────────────────────────────

variable "ingress_gateway_enabled" {
  description = "Enable Application Gateway Ingress Controller (AGIC)"
  type        = bool
  default     = false
}

variable "appgw_subnet_id" {
  description = "The ID of the subnet where Application Gateway will be deployed"
  type        = string
  default     = ""
}

variable "appgw_sku_name" {
  description = "The name of the Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  description = "The tier of the Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_capacity" {
  description = "The number of instances of the Application Gateway (used when autoscaling is disabled)"
  type        = number
  default     = 2
}

variable "appgw_autoscale_enabled" {
  description = "Enable autoscaling for Application Gateway"
  type        = bool
  default     = true
}

variable "appgw_autoscale_min_capacity" {
  description = "Minimum number of instances for Application Gateway autoscaling"
  type        = number
  default     = 0
}

variable "appgw_autoscale_max_capacity" {
  description = "Maximum number of instances for Application Gateway autoscaling"
  type        = number
  default     = 5
}

variable "appgw_availability_zones" {
  description = "Availability zones for the Application Gateway"
  type        = list(string)
  default     = ["1", "2"]
}
