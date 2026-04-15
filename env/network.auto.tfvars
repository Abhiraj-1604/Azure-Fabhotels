address_space                   = ["10.0.0.0/16"]                                  # v_net range 
public_subnet_address_prefixes  = ["10.0.0.0/19", "10.0.32.0/19", "10.0.128.0/24"] #subnet_range1
private_subnet_address_prefixes = ["10.0.64.0/19", "10.0.96.0/19"]                 #subnet_range2

# AKS values (Basics)
aks_cluster_name           = "Fabhotels_dev_cluster"
aks_dns_prefix             = "fabhotelsdev-dns"
aks_sku_tier               = "Free"
aks_kubernetes_version     = "1.35.1" # Confirmed available: az aks get-versions --location "Central India"
aks_default_node_pool_name = "system" # "controlplane" is a reserved/rejected name in AKS
aks_default_vm_size        = "Standard_D2as_v5"
aks_default_min_count      = 1
aks_default_max_count      = 2

# AKS values (Node pools)
aks_additional_node_pools = {
  argonodepool = {
    vm_size   = "Standard_D2as_v5"
    min_count = 1
    max_count = 1
    node_labels = {
      "node-pool" = "argocd"
    }
  }
  marsnp = {
    vm_size   = "Standard_D2as_v5"
    min_count = 1
    max_count = 1
  }
}

# AKS values (Networking)
aks_private_cluster_enabled = false # Private cluster = Azure auto-creates private DNS zone → 30-60+ min extra
aks_network_plugin          = "azure"
aks_network_plugin_mode     = "overlay"
aks_service_cidr            = "172.16.0.0/16"
aks_dns_service_ip          = "172.16.0.10"

# AKS values (Security & Integrations)
aks_oidc_issuer_enabled       = true
aks_workload_identity_enabled = true
aks_azure_policy_enabled      = true

# AAD group Object ID for cluster-admin access via AKS built-in admin_group_object_ids
aks_aad_admin_group_object_ids = ["0bc0616d-6a81-48d2-8e19-085ce98e2d3e"] # Fab-Administrators

# Add users here → Terraform creates a group, adds them, and grants AKS RBAC Cluster Admin
# Get Object ID: az ad user show --id <email> --query id -o tsv
aks_admin_users = [
  "7c0ecbfa-e650-4586-89e8-9022e78b15da", # abhishek@fabhotels1.onmicrosoft.com
  "91f7129a-c2ba-4efa-9534-1ba94a2d4f95"

]





# ACR values
acr_name                    = "fabhotelsdev"
acr_sku                     = "Premium"
acr_zone_redundancy_enabled = true

# Bastion values
bastion_vm_size        = "Standard_B2s"
bastion_admin_username = "azureuser"
