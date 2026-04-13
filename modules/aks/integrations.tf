variable "azure_policy_enabled" { type = bool }

# ── ACR ──────────────────────────────────────────────────────────────────────

variable "acr_id" {
  description = "The ID of the Container Registry to attach to this cluster"
  type        = string
  default     = null
}

variable "attach_acr" {
  description = "Set to true to create the AcrPull role assignment. Must be a static bool (not derived from a resource attribute) to satisfy Terraform plan-time count evaluation."
  type        = bool
  default     = false
}

# Grant the kubelet identity permission to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                            = var.attach_acr ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

# ── AKS Admin Group ───────────────────────────────────────────────────────────

variable "aks_admin_users" {
  description = "List of AAD user Object IDs to add to the AKS Admins group. They will get 'Azure Kubernetes Service RBAC Cluster Admin' role via the group."
  type        = list(string)
  default     = []
}

# Create a dedicated AAD group for AKS cluster admins
resource "azuread_group" "aks_admins" {
  display_name     = "${azurerm_kubernetes_cluster.aks_cluster.name}-admins"
  security_enabled = true
  mail_enabled     = false
}

# Add each user to the AKS Admins group
resource "azuread_group_member" "aks_admin_members" {
  for_each         = toset(var.aks_admin_users)
  group_object_id  = azuread_group.aks_admins.object_id
  member_object_id = each.value
}

# Grant the group AKS RBAC Cluster Admin on the cluster
resource "azurerm_role_assignment" "aks_admins_rbac" {
  principal_id         = azuread_group.aks_admins.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
}
