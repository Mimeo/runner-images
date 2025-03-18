#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Ensure errors in pipes are caught
set -o pipefail

# Download KIND
kind_url=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r '.assets[] | select(.name == "kind-linux-amd64") | .browser_download_url')
kind_binary_path=$(download_with_retry "${kind_url}")

# Supply chain security - KIND
kind_external_hash=$(get_checksum_from_url "${kind_url}.sha256sum" "kind-linux-amd64" "SHA256")
use_checksum_comparison "${kind_binary_path}" "${kind_external_hash}"

# Install KIND
install "${kind_binary_path}" /usr/local/bin/kind

# Install kubectl
kubectl_minor_version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt" | cut -d'.' -f1,2)
curl -fsSL https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${kubectl_minor_version}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
rm -f /etc/apt/sources.list.d/kubernetes.list

# Install Helm
helm_version=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
curl -fsSL -o helm.tar.gz "https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz"

# Supply chain security - Helm
helm_hash_url="https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz.sha256sum"
helm_hash=$(curl -sSL "$helm_hash_url" | awk '{print $1}')
use_checksum_comparison "helm.tar.gz" "${helm_hash}"

# Extract and install Helm
tar -xzf helm.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm.tar.gz linux-amd64

# Download minikube
minikube_url=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r '.assets[] | select(.name == "minikube-linux-amd64") | .browser_download_url')
curl -fsSL -o minikube "$minikube_url"
chmod +x minikube

# Supply chain security - minikube
minikube_hash=$(get_checksum_from_github_release "kubernetes/minikube" "linux-amd64" "latest" "SHA256")
use_checksum_comparison "minikube" "${minikube_hash}"

# Install minikube
install minikube /usr/local/bin/minikube

# Install kustomize
kustomize_version=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | jq -r '.tag_name')
curl -fsSL -o kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/${kustomize_version}/kustomize_${kustomize_version}_linux_amd64.tar.gz"

# Supply chain security - kustomize
kustomize_hash=$(curl -sSL "https://github.com/kubernetes-sigs/kustomize/releases/download/${kustomize_version}/checksums.txt" | grep "kustomize_${kustomize_version}_linux_amd64.tar.gz" | awk '{print $1}')
use_checksum_comparison "kustomize.tar.gz" "${kustomize_hash}"

# Extract and install kustomize
tar -xzf kustomize.tar.gz
mv kustomize /usr/local/bin
rm -f kustomize.tar.gz

invoke_tests "Tools" "Kubernetes tools"
