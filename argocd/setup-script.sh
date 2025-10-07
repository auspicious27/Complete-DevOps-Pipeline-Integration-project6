#!/bin/bash

# ArgoCD Setup Script
# This script installs and configures ArgoCD for GitOps

set -e

echo "🚀 Setting up ArgoCD for GitOps..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we can connect to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_status "Creating ArgoCD namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

print_status "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_status "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd

print_status "Configuring ArgoCD server for external access..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

print_status "Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

print_status "ArgoCD setup completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Get the ArgoCD server URL:"
echo "   kubectl get svc argocd-server -n argocd"
echo ""
echo "2. Access ArgoCD UI:"
echo "   - URL: https://<LOADBALANCER-IP> (or use port-forward)"
echo "   - Username: admin"
echo "   - Password: $ARGOCD_PASSWORD"
echo ""
echo "3. Port forward for local access:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Then access: https://localhost:8080"
echo ""
echo "4. Install ArgoCD CLI:"
echo "   curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "5. Login to ArgoCD CLI:"
echo "   argocd login localhost:8080"
echo ""

print_warning "Remember to change the default admin password after first login!"
print_warning "For production use, configure proper RBAC and remove insecure settings."
