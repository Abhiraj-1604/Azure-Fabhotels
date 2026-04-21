variable "oidc_issuer_enabled" { type = bool }
variable "workload_identity_enabled" { type = bool }

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.cluster_name}-uami"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# UAMI needs Network Contributor on the subnet so AKS can manage NICs and Load Balancers
resource "azurerm_role_assignment" "aks_uami_network_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.vnet_subnet_id
}

# UAMI needs Network Contributor on the VNet to link the auto-managed private DNS zone
# (required when private_cluster_enabled = true and private_dns_zone_id = "System")
resource "azurerm_role_assignment" "aks_uami_network_contributor_vnet" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Network Contributor"
  scope                = var.vnet_id
}
