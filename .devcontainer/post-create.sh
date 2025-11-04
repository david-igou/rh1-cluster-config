#!/bin/bash
# Post-create script for cluster-config development container
# This script runs after the container is created

set -e

echo "🚀 Setting up Cluster Config development environment..."

# Install specific tool versions
echo "📦 Installing development tools..."

# Install yq (YAML processor)
VERSION=v4.40.5
BINARY=yq_linux_amd64
wget -q https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /tmp/yq
sudo mv /tmp/yq /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Install kubeval for Kubernetes YAML validation
wget -q https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz
tar xf kubeval-linux-amd64.tar.gz
sudo mv kubeval /usr/local/bin/
rm kubeval-linux-amd64.tar.gz

# Install kubeconform (modern kubeval alternative)
VERSION=v0.6.4
wget -q https://github.com/yannh/kubeconform/releases/download/${VERSION}/kubeconform-linux-amd64.tar.gz
tar xf kubeconform-linux-amd64.tar.gz
sudo mv kubeconform /usr/local/bin/
rm kubeconform-linux-amd64.tar.gz

# Install Tekton CLI
curl -LO https://github.com/tektoncd/cli/releases/download/v0.33.0/tkn_0.33.0_Linux_x86_64.tar.gz
tar xvzf tkn_0.33.0_Linux_x86_64.tar.gz -C /tmp/
sudo mv /tmp/tkn /usr/local/bin/
rm tkn_0.33.0_Linux_x86_64.tar.gz

# Install ArgoCD CLI
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
rm /tmp/argocd-linux-amd64

# Install Python dependencies
pip install --user --upgrade pip
pip install --user \
    yamllint \
    pre-commit \
    detect-secrets \
    pyyaml \
    jsonschema

# Setup pre-commit
if [ -f .pre-commit-config.yaml ]; then
    echo "🔧 Installing pre-commit hooks..."
    pre-commit install
    pre-commit install --hook-type commit-msg
fi

# Git configuration
echo "⚙️  Configuring Git..."
git config --global --add safe.directory /workspace

# Create helpful aliases
echo "📝 Setting up shell aliases..."
cat >> ~/.bashrc <<'EOF'

# Cluster Config Aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply -f'
alias kustomize-build='kustomize build'
alias validate-k8s='kubeconform -strict -summary'
alias validate-tekton='tkn task validate'
alias argocd-login='argocd login --insecure'

# Git Aliases
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gco='git checkout'

# Quick validation
alias validate-all='yamllint . && kubeconform -strict -summary -output json namespaces/ operators/ aap-instances/ rbac/ argocd/ tekton/'
EOF

source ~/.bashrc

echo "✅ Cluster Config development environment ready!"
echo ""
echo "Available commands:"
echo "  - kubectl, k (alias)"
echo "  - yq (YAML processor)"
echo "  - kustomize"
echo "  - kubeval, kubeconform (validation)"
echo "  - tkn (Tekton CLI)"
echo "  - argocd (ArgoCD CLI)"
echo "  - yamllint, pre-commit"
echo ""
echo "Run 'validate-all' to validate all Kubernetes manifests"

