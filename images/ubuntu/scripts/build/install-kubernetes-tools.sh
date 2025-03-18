#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################

# Source helper scripts
source $HELPER_SCRIPTS/install.sh

# Function to fetch latest GitHub release asset URL
github_latest_url() {
  repo=$1
  asset_pattern=$2
  curl -s "https://api.github.com/repos/$repo/releases/latest" |
    jq -r ".assets[] | select(.name | test(\"$asset_pattern\")) | .browser_download_url"
}

# Install KIND
kind_url=$(github_latest_url "kubernetes-sigs/kind" "kind-linux-amd64")
kind_binary_path=$(download_with_retry "$kind_url")
kind_hash=$(curl -sL "${kind_url}.sha256sum" | awk '{print $1}')
echo "$kind_hash  $kind_binary_path" | sha256sum --check
install "$kind_binary_path" /usr/local/bin/kind

# Install kubectl
kubectl_minor_version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt" | cut -d'.' -f1,2)
curl -fsSL https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
rm -f /etc/apt/sources.list.d/kubernetes.list

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install Minikube
minikube_url=$(github_latest_url "kubernetes/minikube" "minikube-linux-amd64")
curl -fsSL -o minikube "$minikube_url"
chmod +x minikube
minikube_hash=$(curl -sL "${minikube_url}.sha256sum" | awk '{print $1}')
echo "$minikube_hash  minikube" | sha256sum --check
install minikube /usr/local/bin/minikube

# Install Kustomize
kustomize_url="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
curl -fsSL "$kustomize_url" | bash
mv kustomize /usr/local/bin

invoke_tests "Tools" "Kubernetes tools"

echo "✅ Kubernetes tools installed successfully!"
