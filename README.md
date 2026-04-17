# Azure FabHotels — Infrastructure (Terraform)

AKS + ACR + Networking + AGIC on Azure, managed via Terraform with a modular structure.

---

## 📁 Project Structure

```
.
├── .debug-mumbai.sh              # Terraform wrapper — init + plan/apply/destroy
├── main.tf                       # Root module — wires all modules together
├── variables.tf                  # Root variable declarations
├── versions.tf                   # Provider versions (azurerm ~> 4.61, azuread ~> 3.0)
├── outputs.tf                    # Root outputs
├── terraform.tfvars              # Static values (location, project, environment)
├── env/
│   └── network.auto.tfvars       # All environment-specific values
└── modules/
    ├── networking/               # VNet, Subnets, NSG, NAT Gateway
    ├── aks/                      # AKS Cluster, Node Pools, AGIC, App Gateway, RBAC
    ├── container_registry/       # Azure Container Registry
    └── bastion/                  # Bastion VM for cluster access
```

---

## ⚙️ Terraform Workflow

```bash
# Dry run — see what will change
./.debug-mumbai.sh plan

# Create / update resources
./.debug-mumbai.sh apply --auto-approve

# Tear down everything
./.debug-mumbai.sh destroy
```

> The script auto-runs `terraform init` with the remote backend config, then passes `env/network.auto.tfvars`.

---

## 🏗️ Infrastructure Resources

| Resource | Name | Notes |
|---|---|---|
| Resource Group | `rg-fabhotels-dev` | Central India |
| VNet | `vnet-fabhotels-dev` | `10.0.0.0/16` |
| AKS Cluster | `Fabhotels_dev_cluster` | Overlay networking, Azure RBAC |
| App Gateway | `Fabhotels_dev_cluster-appgw` | Standard_v2, autoscale 0–5 |
| Container Registry | `fabhotelsdev` | Premium, zone redundant |
| Bastion VM | `Fab-dev-bastion` | Entra ID SSH, kubectl pre-configured |
| TF State Storage | `stmumbaitfstatedev` | `rg-mumbai-tfstate` |

### Node Pools

| Pool | VM Size | Min | Max | Labels |
|---|---|---|---|---|
| `system` | Standard_D2as_v5 | 1 | 2 | — |
| `argonodepool` | Standard_D2as_v5 | 1 | 1 | `node-pool=argocd` |
| `marsnp` | Standard_D2as_v5 | 1 | 1 | — |

---

## 🚀 New Project Setup

A single `terraform apply` creates everything. Only three CLI pre-requisites — **no Portal steps needed**.

### Step 1 — Create Terraform state backend

```bash
az group create --name rg-<project>-tfstate --location <location>

az storage account create \
  --name st<project>tfstate \
  --resource-group rg-<project>-tfstate \
  --sku Standard_LRS \
  --allow-blob-public-access false

az storage container create \
  --name tfstate-container \
  --account-name st<project>tfstate
```

### Step 2 — Get AAD Object IDs for admin access

```bash
# AAD group object ID (create one if needed)
az ad group create --display-name "Project-Administrators" --mail-nickname "Project-Administrators"
az ad group show --group "Project-Administrators" --query id -o tsv

# User object IDs
az ad user show --id user@domain.com --query id -o tsv
```

### Step 3 — Configure and apply

1. Copy `env/network.auto.tfvars` → update project name, CIDRs, cluster name, ACR name, admin IDs
2. Update `.debug-<project>.sh` with the backend storage details + subscription ID
3. Run `./.debug-<project>.sh apply --auto-approve`

### Required Terraform runner permissions

| Scope | Permission needed |
|---|---|
| Azure Subscription | Owner **or** Contributor + User Access Administrator |
| Entra ID | Application Administrator **or** Group.ReadWrite.All |

---

## 👤 Adding AKS Admin Users

AKS uses **Azure RBAC** with local accounts disabled. Terraform manages a dedicated AAD group and grants it cluster-admin access.

```bash
# 1. Get the user's Object ID
az ad user show --id user@fabhotels1.onmicrosoft.com --query id -o tsv

# 2. Add to env/network.auto.tfvars
aks_admin_users = [
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # user@fabhotels1.onmicrosoft.com
]

# 3. Apply
./.debug-mumbai.sh apply --auto-approve
```

---

## 🔌 Connecting to the AKS Cluster

### From the bastion VM (recommended)
```bash
ssh azureuser@20.235.86.222   # bastion public IP
# kubectl is pre-configured — works immediately
kubectl get ns
```

### From local machine
```bash
az aks get-credentials \
  --resource-group rg-fabhotels-dev \
  --name Fabhotels_dev_cluster \
  --overwrite-existing

kubelogin convert-kubeconfig -l azurecli

kubectl get ns
```

### If you get a "Forbidden" error after being added as admin

Token is cached from before group membership was applied. Force refresh:

```bash
rm -rf ~/.kube/cache
az logout && az login
az aks get-credentials --resource-group rg-fabhotels-dev --name Fabhotels_dev_cluster --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
kubectl get ns
```

---

## 🌐 AGIC — Application Gateway Ingress Controller

AGIC runs as an AKS addon and dynamically programs the Application Gateway based on Kubernetes `Ingress` resources.

### How it works

```
Kubernetes Ingress  ──►  AGIC reads it  ──►  Programs App Gateway  ──►  Traffic routed
```

**Ownership model — Terraform vs AGIC:**

| Terraform owns (infra) | AGIC owns (routing) |
|---|---|
| SKU, availability zones | Backend address pools |
| Subnet attachment, Public IP | HTTP listeners |
| Autoscaling min/max | Request routing rules |
| | Health probes, SSL certs |
| | URL path maps, Redirects |

> **Important:** Terraform will never overwrite AGIC-managed routing config. This is handled via `lifecycle { ignore_changes }` on the `azurerm_application_gateway` resource.

### App Gateway outputs

```bash
terraform output appgw_public_ip_address   # 135.235.177.75
terraform output appgw_name
terraform output appgw_id
terraform output agic_identity_client_id
```

### Enable / disable AGIC

```hcl
# env/network.auto.tfvars
ingress_gateway_enabled      = true         # set false to disable
appgw_sku_name               = "Standard_v2"
appgw_sku_tier               = "Standard_v2"
appgw_autoscale_enabled      = true
appgw_autoscale_min_capacity = 0            # scales to 0 when idle (cost saving)
appgw_autoscale_max_capacity = 5
appgw_availability_zones     = ["1", "2", "3"]
```

### Kubernetes Ingress examples

**Simple HTTP:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: my-app
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

**Path-based routing (multiple services):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: my-app
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /rooms
        pathType: Prefix
        backend:
          service:
            name: rooms-service
            port:
              number: 8080
      - path: /reservations
        pathType: Prefix
        backend:
          service:
            name: reservations-service
            port:
              number: 8080
```

**HTTPS with TLS:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  namespace: my-app
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: app-tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-service
            port:
              number: 443
```

**Useful AGIC annotations:**

| Annotation | Values | Description |
|---|---|---|
| `appgw.ingress.kubernetes.io/backend-protocol` | `http`, `https`, `grpc` | Protocol to backend |
| `appgw.ingress.kubernetes.io/health-probe-path` | `/health` | Health check path |
| `appgw.ingress.kubernetes.io/cookie-based-affinity` | `Enabled`, `Disabled` | Session affinity |
| `appgw.ingress.kubernetes.io/request-timeout` | `30` | Timeout in seconds |
| `appgw.ingress.kubernetes.io/connection-draining-timeout` | `60` | Drain timeout |

### AGIC Troubleshooting

**Backend pools disappear after `terraform apply`**
> This is prevented by the `lifecycle { ignore_changes }` block on the App Gateway. If it still happens, restart AGIC from the bastion:
```bash
kubelogin convert-kubeconfig -l azurecli
kubectl rollout restart deployment ingress-appgw -n ingress-appgw
kubectl logs -n ingress-appgw -l app=ingress-appgw -f
```

**AGIC pod not running / permission errors**
```bash
kubectl get pods -n ingress-appgw
kubectl describe pod -n ingress-appgw -l app=ingress-appgw
kubectl logs -n ingress-appgw -l app=ingress-appgw --tail=50
```

**Verify AGIC addon identity has permissions:**
```bash
az aks show \
  --resource-group rg-fabhotels-dev \
  --name Fabhotels_dev_cluster \
  --query "addonProfiles.ingressApplicationGateway.identity.objectId" -o tsv
```

---

## 🔍 Diagnostic Commands

```bash
# Verify role assignments on the AKS cluster
az role assignment list \
  --scope "/subscriptions/2a1fc2e7-271e-4c68-b79d-603e28cf77aa/resourceGroups/rg-fabhotels-dev/providers/Microsoft.ContainerService/managedClusters/Fabhotels_dev_cluster" \
  --query "[].{Role:roleDefinitionName, Principal:principalName}" -o table

# Check if a user is in the AKS Admins group
az ad group member check \
  --group "Fabhotels_dev_cluster-admins" \
  --member-id "<user-object-id>" \
  --query value

# List all members of the AKS Admins group
az ad group member list \
  --group "Fabhotels_dev_cluster-admins" \
  --query "[].{Name:displayName, Email:mail, OID:id}" -o table

# Check App Gateway backend pool state
az network application-gateway address-pool list \
  --gateway-name "Fabhotels_dev_cluster-appgw" \
  --resource-group "rg-fabhotels-dev-cluster-nodes" -o table
```

---

## 📋 Changelog

### 2026-04-17 — AGIC & Ingress Gateway Fixes

#### Fix 1 — Removed invalid `identity {}` from `ingress_application_gateway` block
**File:** `modules/aks/basic.tf`

The `ingress_application_gateway` block in `azurerm_kubernetes_cluster` does not support an `identity {}` sub-block (AzureRM v4.x). Removed it. AGIC identity permissions are managed via explicit role assignments.

#### Fix 2 — Added AGIC addon identity role assignments
**File:** `modules/aks/ingress_gateway.tf`

When AKS enables AGIC via `ingress_application_gateway`, Azure auto-creates its **own** managed identity for the addon (separate from the user-created `agic_identity` UAMI). This identity needs `Network Contributor` on the App Gateway subnet **and** VNet. Without this, AGIC cannot program the Application Gateway.

Two new resources added — `agic_addon_identity_network_contributor_subnet` and `agic_addon_identity_network_contributor_vnet` — both reading the object ID from `aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id`.

**Identity summary:**

| Identity | Source | Permissions |
|---|---|---|
| `agic_identity` UAMI | User-created by Terraform | Contributor on node RG, Reader on main RG, Network Contributor on subnet + VNet |
| AKS AGIC Addon MSI | Auto-created by Azure on cluster creation | **Network Contributor on subnet + VNet** ← was the missing piece |

#### Fix 3 — App Gateway `lifecycle { ignore_changes }` for AGIC ownership
**File:** `modules/aks/ingress_gateway.tf`

Without lifecycle protection, every `terraform apply` resets the App Gateway to Terraform's placeholder config — wiping all AGIC-managed rules (ArgoCD backend pool, listeners, routing rules). Added `ignore_changes` for all AGIC-owned attributes: `backend_address_pool`, `backend_http_settings`, `frontend_port`, `http_listener`, `probe`, `redirect_configuration`, `request_routing_rule`, `ssl_certificate`, `url_path_map`, `tags`.

#### Fix 4 — Bastion role assignment scope casing
**File:** `modules/bastion/main.tf`

Azure ARM API returns scope paths with lowercase `resourcegroups` but Terraform sends `resourceGroups`. This permanent Azure API quirk causes a diff on every plan → forced destroy+recreate. Added `lifecycle { ignore_changes = [scope] }` to both `bastion_vm_admin_group` and `bastion_vm_admin_users`.