#!/bin/bash -e
################################################################################
##  File:  install-kubernetes-tools.sh
##  Desc:  Installs kubectl, helm, kustomize
##  Supply chain security: KIND, minikube - checksum validation
################################################################################
# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

# Install KIND
kind_url=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r '.assets[] | select(.name == "kind-linux-amd64") | .browser_download_url')
if [[ -z "$kind_url" ]]; then
    echo "Failed to fetch the latest KIND release URL. Exiting."
    exit 1
fi

curl -fsSL -o kind "$kind_url"
chmod +x kind

kind_hash=$(curl -s "$kind_url.sha256sum" | awk '{print $1}')
echo "$kind_hash  kind" | sha256sum --check --status || { echo "Checksum failed!"; exit 1; }

install kind /usr/local/bin/kind

# Install kubectl
kubectl_minor_version=$(curl -fsSL "https://dl.k8s.io/release/stable.txt" | cut -d'.' -f1,2 )
curl -fsSL https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$kubectl_minor_version/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
rm -f /etc/apt/sources.list.d/kubernetes.list

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install minikube
minikube_url=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | jq -r '.assets[] | select(.name == "minikube-linux-amd64") | .browser_download_url')
if [[ -z "$minikube_url" ]]; then
    echo "Failed to fetch the latest Minikube release URL. Exiting."
    exit 1
fi

curl -fsSL -o minikube "$minikube_url"
chmod +x minikube

minikube_hash=$(curl -s "$minikube_url.sha256sum" | awk '{print $1}')
echo "$minikube_hash  minikube" | sha256sum --check --status || { echo "Checksum failed!"; exit 1; }

install minikube /usr/local/bin/minikube

# Install kustomize
kustomize_url="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
curl -fsSL "$kustomize_url" | bash
mv kustomize /usr/local/bin

invoke_tests "Tools" "Kubernetes tools"
