data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  # --- BASICS CONFIGURATION ---
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  node_resource_group = "${var.resource_group_name}-cluster-nodes"
  dns_prefix          = var.dns_prefix
  sku_tier            = var.sku_tier
  kubernetes_version  = var.kubernetes_version

  # NOTE: Upgrade channels removed — they add significant time during initial cluster creation.
  # Re-enable post-deployment: automatic_upgrade_channel = "patch", node_os_upgrade_channel = "NodeImage"

  # --- SECURITY CONFIGURATION ---
  local_account_disabled = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = var.aad_admin_group_object_ids
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  # --- INTEGRATIONS CONFIGURATION ---
  azure_policy_enabled = var.azure_policy_enabled

  # Application Gateway Ingress Controller integration
  dynamic "ingress_application_gateway" {
    for_each = var.ingress_gateway_enabled ? [1] : []
    content {
      gateway_id = azurerm_application_gateway.appgw[0].id
    }
  }

  # --- DEFAULT NODEPOOL CONFIGURATION ---
  default_node_pool {
    name                 = var.default_node_pool_name
    vm_size              = var.default_vm_size
    auto_scaling_enabled = true
    min_count            = var.default_min_count
    max_count            = var.default_max_count
    vnet_subnet_id       = var.vnet_subnet_id
    os_sku               = "Ubuntu"
    os_disk_size_gb      = 64        # Explicit disk size avoids slow auto-sizing
    os_disk_type         = "Managed" # Ephemeral is fastest but requires large VM; Managed is safe default

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # --- NETWORKING CONFIGURATION ---
  private_cluster_enabled = var.private_cluster_enabled

  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = var.network_plugin_mode
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }



  # --- TAGS ---
  tags = var.tags

  # Ensure Application Gateway is created first if AGIC is enabled
  depends_on = [azurerm_application_gateway.appgw]
}

