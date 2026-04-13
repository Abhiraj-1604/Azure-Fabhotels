#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Retry wrapper for network-dependent commands
retry() {
  local retries=5
  local count=0
  until "$@"; do
    count=$((count + 1))
    if [ $count -ge $retries ]; then
      echo "ERROR: Command failed after $retries attempts: $*"
      return 1
    fi
    echo "RETRY ($count/$retries): $* — waiting 10s..."
    sleep 10
  done
}

# Wait for any unattended-upgrades or dpkg locks to clear first
for i in $(seq 1 30); do
  if ! fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && \
     ! fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
    break
  fi
  echo "Waiting for dpkg/apt lock to be released... ($i/30)"
  sleep 10
done

# Update and install dependencies
retry apt-get update -y
retry apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release jq wget unzip

# Add Microsoft package signing key + repos
mkdir -p /etc/apt/keyrings
retry curl -sLS https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
cat /tmp/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
ARCH=$(dpkg --print-architecture)

# Azure CLI repo
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" \
  > /etc/apt/sources.list.d/azure-cli.list

# Microsoft Ubuntu prod repo (for aadsshlogin)
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod $AZ_DIST main" \
  > /etc/apt/sources.list.d/microsoft-prod.list

retry apt-get update -y

# Install Azure CLI
retry apt-get install -y azure-cli

# Install AAD SSH Login — enables Entra ID based SSH authentication
retry apt-get install -y aadsshlogin

# Install kubectl
retry curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key -o /tmp/k8s.key
cat /tmp/k8s.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list
retry apt-get update -y
retry apt-get install -y kubectl

# Install kubelogin (Azure AD auth plugin for kubectl)
KUBELOGIN_VERSION="v0.1.3"
retry wget -q "https://github.com/Azure/kubelogin/releases/download/$KUBELOGIN_VERSION/kubelogin-linux-amd64.zip" -O /tmp/kubelogin.zip
unzip -o /tmp/kubelogin.zip -d /tmp/kubelogin
mv /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/local/bin/
chmod +x /usr/local/bin/kubelogin
rm -rf /tmp/kubelogin.zip /tmp/kubelogin

# Install Helm
retry curl -fsSL https://baltocdn.com/helm/signing.asc -o /tmp/helm.asc
cat /tmp/helm.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg
echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" \
  > /etc/apt/sources.list.d/helm-stable-debian.list
retry apt-get update -y
retry apt-get install -y helm

# Login with VM's Managed Identity and fetch the AKS kubeconfig for all users
retry az login --identity
mkdir -p /etc/kubernetes
retry az aks get-credentials -g ${rg_name} -n ${aks_name} -f /etc/kubernetes/kubeconfig
chmod 644 /etc/kubernetes/kubeconfig

# Set KUBECONFIG globally so every SSH user gets it automatically
cat > /etc/profile.d/k8s_env.sh << 'PROFILE_EOF'
export KUBECONFIG=/etc/kubernetes/kubeconfig
PROFILE_EOF
chmod +x /etc/profile.d/k8s_env.sh

echo "=== Cloud-init completed successfully ==="
