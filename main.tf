module "network" {
  source                          = "./modules/networking"
  environment                     = var.environment
  project                         = var.project
  address_space                   = var.address_space
  location                        = var.location
  region                          = var.region
  private_subnet_address_prefixes = var.private_subnet_address_prefixes
  public_subnet_address_prefixes  = var.public_subnet_address_prefixes
}

module "container_registry" {
  source                  = "./modules/container_registry"
  acr_name                = var.acr_name
  resource_group_name     = module.network.resource_group_name
  location                = var.location
  sku                     = var.acr_sku
  admin_enabled           = false
  zone_redundancy_enabled = var.acr_zone_redundancy_enabled

  depends_on = [module.network]
}

module "aks" {
  source                      = "./modules/aks"
  cluster_name                = var.aks_cluster_name
  location                    = var.location
  resource_group_name         = module.network.resource_group_name
  dns_prefix                  = var.aks_dns_prefix
  sku_tier                    = var.aks_sku_tier
  kubernetes_version          = var.aks_kubernetes_version
  
  default_node_pool_name      = var.aks_default_node_pool_name
  default_vm_size             = var.aks_default_vm_size
  default_min_count           = var.aks_default_min_count
  default_max_count           = var.aks_default_max_count
  
  vnet_subnet_id              = module.network.private_subnet_1_id
  additional_node_pools       = var.aks_additional_node_pools
  
  private_cluster_enabled     = var.aks_private_cluster_enabled
  network_plugin              = var.aks_network_plugin
  network_plugin_mode         = var.aks_network_plugin_mode
  service_cidr                = var.aks_service_cidr
  dns_service_ip              = var.aks_dns_service_ip

  oidc_issuer_enabled         = var.aks_oidc_issuer_enabled
  workload_identity_enabled   = var.aks_workload_identity_enabled
  azure_policy_enabled        = var.aks_azure_policy_enabled

  acr_id                      = module.container_registry.acr_id
  attach_acr                  = true
  aad_admin_group_object_ids  = var.aks_aad_admin_group_object_ids
  aks_admin_users             = var.aks_admin_users


  depends_on = [module.network, module.container_registry]
}
