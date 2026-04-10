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
