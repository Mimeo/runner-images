#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################
# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install jq (needed for JSON parsing)
apt-get update && apt-get install -y jq

# Download and install KIND
kind_version=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
kind_url="https://github.com/kubernetes-sigs/kind/releases/download/${kind_version}/kind-linux-amd64"
kind_checksum_url="${kind_url}.sha256sum"

curl -fsSL -o kind "${kind_url}"
chmod +x kind

# Fetch checksum and validate
kind_checksum=$(curl -fsSL "${kind_checksum_url}" | awk '{print $1}')
echo "${kind_checksum}  kind" | sha256sum --check --status || { echo "❌ KIND checksum validation failed!"; exit 1; }

install kind /usr/local/bin/kind

# Install kubectl
kubectl_version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt")
kubectl_url="https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl"
kubectl_checksum_url="${kubectl_url}.sha256"

curl -fsSL -o kubectl "${kubectl_url}"
chmod +x kubectl

# Validate kubectl checksum
kubectl_checksum=$(curl -fsSL "${kubectl_checksum_url}")
echo "${kubectl_checksum}  kubectl" | sha256sum --check --status || { echo "❌ kubectl checksum validation failed!"; exit 1; }

install kubectl /usr/local/bin/kubectl

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Download and install minikube
minikube_version=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r .tag_name)
minikube_url="https://github.com/kubernetes/minikube/releases/download/${minikube_version}/minikube-linux-amd64"
minikube_checksum_url="${minikube_url}.sha256"

curl -fsSL -o minikube "${minikube_url}"
chmod +x minikube

# Validate minikube checksum
minikube_checksum=$(curl -fsSL "${minikube_checksum_url}")
echo "${minikube_checksum}  minikube" | sha256sum --check --status || { echo "❌ Minikube checksum validation failed!"; exit 1; }

install minikube /usr/local/bin/minikube

# Install kustomize
kustomize_url="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
curl -fsSL "$kustomize_url" | bash
mv kustomize /usr/local/bin

invoke_tests "Tools" "Kubernetes tools"

echo "✅ All Kubernetes tools installed successfully!"
