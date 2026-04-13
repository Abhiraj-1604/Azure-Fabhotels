# Azure Fabhotels — Infrastructure (Terraform)

AKS + ACR + Networking on Azure, managed via Terraform with modular structure.

---

## 📁 Project Structure

```
.
├── main.tf                   # Root module — wires all modules together
├── variables.tf              # Root variable declarations
├── versions.tf               # Provider versions (azurerm + azuread)
├── outputs.tf                # Root outputs
├── terraform.tfvars          # Static values (location, project, env)
├── .debug-mumbai.sh          # Terraform wrapper script (init + plan/apply)
├── env/
│   └── network.auto.tfvars   # All environment-specific values
└── modules/
    ├── networking/           # VNet, Subnets, NSG, NAT Gateway
    ├── aks/                  # AKS Cluster, Node Pools, RBAC, ACR integration
    └── container_registry/   # Azure Container Registry
```

---

## ⚙️ Terraform Workflow

### Plan (dry run — see what will change)
```bash
./.debug-mumbai.sh plan
```

### Apply (create/update resources)
```bash
./.debug-mumbai.sh apply
```

### Destroy (tear down everything)
```bash
./.debug-mumbai.sh destroy
```

> The script auto-runs `terraform init` with the remote backend, then passes the env tfvars file.

---

## 👤 Adding AKS Admin Users

AKS uses **Azure RBAC** (`azure_rbac_enabled = true`) with local accounts disabled.  
Terraform manages a dedicated AAD group `Fabhotels_dev_cluster-admins` and grants it cluster-admin access.

### Step 1 — Get the user's Azure Object ID
```bash
az ad user show --id <user@fabhotels1.onmicrosoft.com> --query id -o tsv
```

### Step 2 — Add to `env/network.auto.tfvars`
```hcl
aks_admin_users = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",   # user@fabhotels1.onmicrosoft.com
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",   # another@fabhotels1.onmicrosoft.com
]
```

### Step 3 — Apply
```bash
./.debug-mumbai.sh apply
```

---

## 🔌 Connecting to the AKS Cluster

### First-time setup
```bash
# 1. Fetch kubeconfig
az aks get-credentials \
  --resource-group rg-fabhotels-dev \
  --name Fabhotels_dev_cluster \
  --overwrite-existing

# 2. Convert to Azure CLI auth (required when local accounts are disabled)
kubelogin convert-kubeconfig -l azurecli

# 3. Test
kubectl get ns
```

### If you get a "Forbidden" error after being added as admin
Your Azure CLI token may be stale (cached before group membership was updated). Force a full refresh:

```bash
# Clear cached tokens
rm -rf ~/.kube/cache
rm -rf ~/.azure/accessTokens.json 2>/dev/null

# Re-login to Azure
az logout
az login

# Re-fetch kubeconfig and reconnect
az aks get-credentials \
  --resource-group rg-fabhotels-dev \
  --name Fabhotels_dev_cluster \
  --overwrite-existing

kubelogin convert-kubeconfig -l azurecli

# Test
kubectl get ns
```

---

## 🔍 Useful Diagnostic Commands

### Verify role assignments on the AKS cluster
```bash
az role assignment list \
  --scope "/subscriptions/2a1fc2e7-271e-4c68-b79d-603e28cf77aa/resourceGroups/rg-fabhotels-dev/providers/Microsoft.ContainerService/managedClusters/Fabhotels_dev_cluster" \
  --query "[].{Role:roleDefinitionName, Principal:principalName}" \
  --output table
```

### Check if a user is in the AKS Admins group
```bash
az ad group member check \
  --group "Fabhotels_dev_cluster-admins" \
  --member-id "<user-object-id>" \
  --query value
```

### List all members of the AKS Admins group
```bash
az ad group member list \
  --group "Fabhotels_dev_cluster-admins" \
  --query "[].{Name:displayName, Email:mail, OID:id}" \
  --output table
```

### Get your own Object ID
```bash
az ad signed-in-user show --query id -o tsv
```

### Check current kubectl context
```bash
kubectl config current-context
kubectl config get-contexts
```

### Switch kubectl context
```bash
kubectl config use-context <context-name>
```

---

## 🏗️ Infrastructure Details

| Resource | Name | Location |
|---|---|---|
| Resource Group | `rg-fabhotels-dev` | Central India |
| VNet | `vnet-fabhotels-dev` | `10.0.0.0/16` |
| AKS Cluster | `Fabhotels_dev_cluster` | Central India |
| Container Registry | `fabhotelsdev` | Central India |
| TF State Storage | `stmumbaitfstatedev` | Central India |

### Node Pools
| Pool | VM Size | Min | Max |
|---|---|---|---|
| `system` (default) | Standard_D2as_v5 | 1 | 2 |
| `argonodepool` | Standard_D2as_v5 | 1 | 1 |
| `marsnp` | Standard_D2as_v5 | 1 | 1 |