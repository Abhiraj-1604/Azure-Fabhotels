output "bastion_public_ip" {
  description = "The public IP address of the bastion"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "bastion_private_key" {
  description = "The private SSH key of the bastion"
  value       = tls_private_key.bastion_ssh.private_key_pem
  sensitive   = true
}
