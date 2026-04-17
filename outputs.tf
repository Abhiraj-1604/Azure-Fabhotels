output "vnet_id" {
  value = module.network.vnet_id
}

output "vnet_name" {
  value = module.network.vnet_name
}

output "nsg_public_id" {
  value = module.network.nsg_public_id
}

output "nsg_private_id" {
  value = module.network.nsg_private_id
}

output "nat_gateway_id" {
  value = module.network.nat_gateway_id
}

output "nat_gateway_public_ip" {
  value = module.network.nat_gateway_public_ip
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "bastion_private_key" {
  value     = module.bastion.bastion_private_key
  sensitive = true
}

# ── INGRESS GATEWAY OUTPUTS ──────────────────────────────────────────────────

output "appgw_id" {
  description = "The ID of the Application Gateway"
  value       = module.aks.appgw_id
}

output "appgw_name" {
  description = "The name of the Application Gateway"
  value       = module.aks.appgw_name
}

output "appgw_public_ip_address" {
  description = "The public IP address of the Application Gateway"
  value       = module.aks.appgw_public_ip_address
}

output "agic_identity_client_id" {
  description = "The Client ID of the AGIC managed identity"
  value       = module.aks.agic_identity_client_id
}

output "agic_identity_id" {
  description = "The ID of the AGIC managed identity"
  value       = module.aks.agic_identity_id
}
