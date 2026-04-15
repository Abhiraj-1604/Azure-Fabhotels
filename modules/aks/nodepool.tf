# --- NEW / ADDITIONAL NODE POOLS (like argonodepool) ---
resource "azurerm_kubernetes_cluster_node_pool" "additional_nodepool" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = each.value.vm_size

  auto_scaling_enabled = true
  min_count            = each.value.min_count
  max_count            = each.value.max_count

  vnet_subnet_id  = var.vnet_subnet_id
  mode            = "User"
  os_sku          = "Ubuntu"
  os_disk_size_gb = 64
  os_disk_type    = "Managed"
  node_labels     = each.value.node_labels != null ? each.value.node_labels : {}

  tags = var.tags

  upgrade_settings {
    max_surge = "10%"
  }
}
