# ── APPLICATION GATEWAY INGRESS CONTROLLER (AGIC) ───────────────────────────────

# Local to determine autoscale configuration and construct VNet scope from subnet ID
locals {
  # When autoscaling is enabled, use autoscale config; when disabled, use fixed capacity
  appgw_autoscale_config = var.appgw_autoscale_enabled ? {
    min_capacity = var.appgw_autoscale_min_capacity
    max_capacity = var.appgw_autoscale_max_capacity
  } : null

  # Node resource group where App Gateway should be deployed
  node_resource_group = "${var.resource_group_name}-cluster-nodes"

  # Extract VNet ID from subnet ID by removing /subnets/subnetname
  # Subnet ID format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}
  # VNet ID format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}
  appgw_vnet_id = var.ingress_gateway_enabled ? split("/subnets/", var.appgw_subnet_id)[0] : ""
}

# User-assigned managed identity for Application Gateway (used by AGIC)
resource "azurerm_user_assigned_identity" "agic_identity" {
  count               = var.ingress_gateway_enabled ? 1 : 0
  name                = "${var.cluster_name}-agic-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Grant AGIC identity Contributor role on the node resource group (for managing App Gateway)
# NOTE: depends_on AKS cluster because node_resource_group is created by Azure during cluster provisioning
resource "azurerm_role_assignment" "agic_contributor_node_rg" {
  count                = var.ingress_gateway_enabled ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.node_resource_group}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic_identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]

  # scope becomes (known after apply) when data.client_config re-reads → forces replacement
  lifecycle {
    ignore_changes = [scope, principal_type, role_definition_id, skip_service_principal_aad_check]
  }
}

# Grant AGIC identity Reader role on the main resource group
resource "azurerm_role_assignment" "agic_reader_main_rg" {
  count                = var.ingress_gateway_enabled ? 1 : 0
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic_identity[0].principal_id

  # scope becomes (known after apply) when data.client_config re-reads → forces replacement
  lifecycle {
    ignore_changes = [scope, principal_type, role_definition_id, skip_service_principal_aad_check]
  }
}

# Grant AGIC identity Network Contributor role on the App Gateway subnet (required for AGIC to manage App Gateway)
resource "azurerm_role_assignment" "agic_network_contributor_subnet" {
  count                = var.ingress_gateway_enabled ? 1 : 0
  scope                = var.appgw_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agic_identity[0].principal_id
}

# Grant AGIC identity Network Contributor role on the Virtual Network (required for subnets/join/action)
resource "azurerm_role_assignment" "agic_network_contributor_vnet" {
  count                = var.ingress_gateway_enabled ? 1 : 0
  scope                = local.appgw_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agic_identity[0].principal_id
}

# Public IP for Application Gateway
# NOTE: deployed in main resource group (not node RG) to avoid a dependency cycle:
#   appgw_pip → [depends_on] → aks_cluster → appgw → appgw_pip
resource "azurerm_public_ip" "appgw_pip" {
  count               = var.ingress_gateway_enabled ? 1 : 0
  name                = "${var.cluster_name}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.appgw_availability_zones

  tags = var.tags
}

# Application Gateway
# ─────────────────────────────────────────────────────────────────────────────
# OWNERSHIP MODEL:
#   Terraform owns  → SKU, zones, subnet attachment, public IP, autoscaling
#   AGIC owns       → backend pools, listeners, routing rules, probes, SSL certs
#                     (AGIC programs these dynamically from Kubernetes Ingress objects)
#
# Without lifecycle ignore_changes, every `terraform apply` resets the App Gateway
# back to Terraform's placeholder config — wiping all AGIC-managed rules and
# forcing AGIC to re-reconcile from scratch (losing ArgoCD/app backend pools).
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_application_gateway" "appgw" {
  count               = var.ingress_gateway_enabled ? 1 : 0
  name                = "${var.cluster_name}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.appgw_availability_zones

  sku {
    name     = var.appgw_sku_name
    tier     = var.appgw_sku_tier
    capacity = var.appgw_autoscale_enabled ? null : var.appgw_capacity
  }

  # Autoscaling configuration (only when enabled)
  dynamic "autoscale_configuration" {
    for_each = var.appgw_autoscale_enabled ? [1] : []
    content {
      min_capacity = var.appgw_autoscale_min_capacity
      max_capacity = var.appgw_autoscale_max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip[0].id
  }

  # ── Placeholder config (bootstrap only) ──────────────────────────────────
  # These blocks satisfy the Terraform provider schema requirement for at least
  # one of each. AGIC will replace/extend all of these after its first sync.
  # They are protected by ignore_changes below — Terraform will NOT reset them.

  frontend_port {
    name = "appgw-frontend-port-80"
    port = 80
  }

  frontend_port {
    name = "appgw-frontend-port-443"
    port = 443
  }

  backend_address_pool {
    name = "appgw-backend-pool"
  }

  backend_http_settings {
    name                  = "appgw-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "appgw-frontend-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appgw-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-http-listener"
    backend_address_pool_name  = "appgw-backend-pool"
    backend_http_settings_name = "appgw-http-settings"
    priority                   = 10
  }

  tags = var.tags

  # ── AGIC owns the routing layer — Terraform must not overwrite it ─────────
  lifecycle {
    ignore_changes = [
      backend_address_pool,      # AGIC adds pools per Ingress (e.g. ArgoCD, apps)
      backend_http_settings,     # AGIC adds HTTP settings per Ingress
      frontend_port,             # AGIC may add ports (e.g. custom HTTPS ports)
      http_listener,             # AGIC adds listeners per Ingress host/path
      probe,                     # AGIC adds health probes per backend
      redirect_configuration,    # AGIC adds HTTP→HTTPS redirects
      request_routing_rule,      # AGIC adds routing rules per Ingress
      ssl_certificate,           # AGIC manages TLS certificates
      url_path_map,              # AGIC adds path-based routing maps
      tags,                      # AGIC may annotate with its own tags
      identity,                  # AGIC attaches appgw-kv-identity for Key Vault cert access
    ]
  }

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}


# ── AKS AGIC ADDON IDENTITY ROLE ASSIGNMENTS ─────────────────────────────────
# When AKS enables AGIC via ingress_application_gateway, Azure creates its OWN
# managed identity for the AGIC add-on (separate from agic_identity above).
# This identity also needs Network Contributor on the subnet and VNet to manage
# App Gateway networking. Without this, AGIC will fail with permission errors.

resource "azurerm_role_assignment" "agic_addon_identity_network_contributor_subnet" {
  count                            = var.ingress_gateway_enabled ? 1 : 0
  scope                            = var.appgw_subnet_id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  skip_service_principal_aad_check = true

  # NOTE: Role assignments do not support in-place updates.
  # If this resource was pre-created manually (without skip_service_principal_aad_check),
  # Terraform would try to update it and fail. ignore_changes prevents that.
  # On a FRESH deployment Terraform creates it correctly from day one — no drift occurs.
  lifecycle {
    ignore_changes = [skip_service_principal_aad_check]
  }

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

resource "azurerm_role_assignment" "agic_addon_identity_network_contributor_vnet" {
  count                = var.ingress_gateway_enabled ? 1 : 0
  scope                = local.appgw_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  skip_service_principal_aad_check = true

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

# Federated identity credential for AGIC pod identity
resource "azurerm_federated_identity_credential" "agic_federated_identity" {
  count     = var.ingress_gateway_enabled && var.workload_identity_enabled ? 1 : 0
  name      = "${var.cluster_name}-agic-fed-identity"
  audience  = ["api://AzureADTokenExchange"]
  issuer    = azurerm_kubernetes_cluster.aks_cluster.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.agic_identity[0].id
  subject   = "system:serviceaccount:ingress-appgw:ingress-appgw-sa"
}
