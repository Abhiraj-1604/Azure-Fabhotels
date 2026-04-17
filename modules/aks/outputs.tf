output "kube_config" {
  description = "Raw Kubernetes config to be used by kubectl and other clients."
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive   = true
}

output "cluster_id" {
  description = "The ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks_cluster.id
}

output "cluster_name" {
  description = "The name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

# ── INGRESS GATEWAY OUTPUTS ──────────────────────────────────────────────────

output "appgw_id" {
  description = "The ID of the Application Gateway"
  value       = var.ingress_gateway_enabled ? azurerm_application_gateway.appgw[0].id : null
}

output "appgw_name" {
  description = "The name of the Application Gateway"
  value       = var.ingress_gateway_enabled ? azurerm_application_gateway.appgw[0].name : null
}

output "appgw_public_ip_address" {
  description = "The public IP address of the Application Gateway"
  value       = var.ingress_gateway_enabled ? azurerm_public_ip.appgw_pip[0].ip_address : null
}

output "agic_identity_client_id" {
  description = "The Client ID of the AGIC managed identity"
  value       = var.ingress_gateway_enabled ? azurerm_user_assigned_identity.agic_identity[0].client_id : null
}

output "agic_identity_id" {
  description = "The ID of the AGIC managed identity"
  value       = var.ingress_gateway_enabled ? azurerm_user_assigned_identity.agic_identity[0].id : null
}
