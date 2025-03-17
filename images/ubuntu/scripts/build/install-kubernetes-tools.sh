#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Download KIND
echo "Fetching latest KIND release..."

# Fetch the latest release JSON from GitHub API and find any linux amd64 binary
kind_url=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest \
  | grep -oP '"browser_download_url": "\K(https.*?linux.*?amd64.*?)"')

# Fallback if no binary is found
if [[ -z "$kind_url" ]]; then
  echo "🚨 Failed to locate a suitable KIND binary."
  exit 1
fi

echo "✅ Found KIND binary: $kind_url"

# Download KIND binary
kind_binary_path=$(download_with_retry "$kind_url")

# Supply chain security - KIND
kind_external_hash=$(get_checksum_from_url "${kind_url}.sha256sum" "$(basename $kind_url)" "SHA256")
use_checksum_comparison "${kind_binary_path}" "${kind_external_hash}"

# Install KIND
install "${kind_binary_path}" /usr/local/bin/kind

## Install kubectl
kubectl_minor_version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt" | cut -d'.' -f1,2 )
curl -fsSL https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'$kubectl_minor_version'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install kubectl
rm -f /etc/apt/sources.list.d/kubernetes.list

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Download minikube
curl -fsSL -O https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Supply chain security - minikube
minikube_hash=$(get_checksum_from_github_release "kubernetes/minikube" "linux-amd64" "latest" "SHA256")
use_checksum_comparison "minikube-linux-amd64" "${minikube_hash}"

# Install minikube
install minikube-linux-amd64 /usr/local/bin/minikube

# Install kustomize
download_url="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
curl -fsSL "$download_url" | bash
mv kustomize /usr/local/bin

invoke_tests "Tools" "Kubernetes tools"
