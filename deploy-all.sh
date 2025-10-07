#!/bin/bash

# Complete DevOps Pipeline Integration - Deployment Script
# This script deploys the entire DevOps pipeline stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACES=("argocd" "jenkins" "sonarqube" "security" "monitoring" "velero")

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
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
    
    # Check if we have sufficient resources
    local nodes=$(kubectl get nodes --no-headers | wc -l)
    if [ "$nodes" -lt 1 ]; then
        print_error "No nodes found in the cluster"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create namespaces
create_namespaces() {
    print_header "Creating Namespaces"
    
    for namespace in "${NAMESPACES[@]}"; do
        print_step "Creating namespace: $namespace"
        kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
    done
    
    print_success "All namespaces created"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_header "Deploying ArgoCD (GitOps)"
    
    print_step "Installing ArgoCD"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    print_step "Waiting for ArgoCD to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd
    
    print_step "Configuring ArgoCD server for external access"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    
    print_success "ArgoCD deployed successfully"
}

# Function to deploy Jenkins
deploy_jenkins() {
    print_header "Deploying Jenkins (CI/CD)"
    
    print_step "Installing Jenkins"
    kubectl apply -f "$SCRIPT_DIR/jenkins/jenkins-deployment.yaml"
    
    print_step "Waiting for Jenkins to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins
    
    print_success "Jenkins deployed successfully"
}

# Function to deploy SonarQube
deploy_sonarqube() {
    print_header "Deploying SonarQube (Code Quality)"
    
    print_step "Installing SonarQube"
    kubectl apply -f "$SCRIPT_DIR/security/sonarqube-deployment.yaml"
    
    print_step "Waiting for SonarQube to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube
    kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n sonarqube
    
    print_success "SonarQube deployed successfully"
}

# Function to deploy Trivy
deploy_trivy() {
    print_header "Deploying Trivy (Security Scanning)"
    
    print_step "Installing Trivy scanning jobs"
    kubectl apply -f "$SCRIPT_DIR/security/trivy-scan-job.yaml"
    
    print_success "Trivy deployed successfully"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_header "Deploying Monitoring Stack"
    
    print_step "Installing Prometheus"
    kubectl apply -f "$SCRIPT_DIR/monitoring/prometheus-deployment.yaml"
    
    print_step "Installing Grafana"
    kubectl apply -f "$SCRIPT_DIR/monitoring/grafana-deployment.yaml"
    
    print_step "Waiting for monitoring stack to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
    
    print_success "Monitoring stack deployed successfully"
}

# Function to deploy Velero
deploy_velero() {
    print_header "Deploying Velero (Backup & DR)"
    
    print_step "Installing Velero"
    kubectl apply -f "$SCRIPT_DIR/backup/velero-install.yaml"
    
    print_step "Installing backup schedules"
    kubectl apply -f "$SCRIPT_DIR/backup/backup-schedule.yaml"
    
    print_step "Waiting for Velero to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/velero -n velero
    
    print_success "Velero deployed successfully"
}

# Function to deploy sample applications
deploy_applications() {
    print_header "Deploying Sample Applications"
    
    print_step "Deploying to Development environment"
    kubectl apply -k "$SCRIPT_DIR/environments/dev/"
    
    print_step "Deploying to Staging environment"
    kubectl apply -k "$SCRIPT_DIR/environments/staging/"
    
    print_step "Deploying to Production environment"
    kubectl apply -k "$SCRIPT_DIR/environments/prod/"
    
    print_step "Deploying Blue-Green setup"
    kubectl apply -f "$SCRIPT_DIR/blue-green/blue-deployment.yaml"
    kubectl apply -f "$SCRIPT_DIR/blue-green/green-deployment.yaml"
    
    print_success "Sample applications deployed successfully"
}

# Function to deploy ArgoCD applications
deploy_argocd_apps() {
    print_header "Deploying ArgoCD Applications"
    
    print_step "Creating ArgoCD applications"
    kubectl apply -f "$SCRIPT_DIR/argocd/sample-application.yaml"
    
    print_success "ArgoCD applications deployed successfully"
}

# Function to get access information
get_access_info() {
    print_header "Access Information"
    
    echo ""
    print_status "🔗 ArgoCD UI:"
    echo "   URL: https://$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost:8080')"
    echo "   Username: admin"
    echo "   Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo 'Check ArgoCD namespace')"
    echo ""
    
    print_status "🔗 Jenkins UI:"
    echo "   URL: http://$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost:8081')"
    echo "   Username: admin"
    echo "   Password: $(kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || echo 'Check Jenkins namespace')"
    echo ""
    
    print_status "🔗 SonarQube UI:"
    echo "   URL: http://$(kubectl get svc sonarqube -n sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost:9000')"
    echo "   Username: admin"
    echo "   Password: admin"
    echo ""
    
    print_status "🔗 Prometheus UI:"
    echo "   URL: http://$(kubectl get svc prometheus -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost:9090')"
    echo ""
    
    print_status "🔗 Grafana UI:"
    echo "   URL: http://$(kubectl get svc grafana -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'localhost:3000')"
    echo "   Username: admin"
    echo "   Password: admin"
    echo ""
    
    print_warning "If using port-forward, run these commands:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   kubectl port-forward svc/jenkins -n jenkins 8081:8080"
    echo "   kubectl port-forward svc/sonarqube -n sonarqube 9000:9000"
    echo "   kubectl port-forward svc/prometheus -n monitoring 9090:9090"
    echo "   kubectl port-forward svc/grafana -n monitoring 3000:3000"
}

# Function to show deployment status
show_status() {
    print_header "Deployment Status"
    
    echo ""
    print_status "📊 Namespace Status:"
    for namespace in "${NAMESPACES[@]}"; do
        local status=$(kubectl get namespace $namespace -o jsonpath='{.status.phase}' 2>/dev/null || echo "Not Found")
        echo "   $namespace: $status"
    done
    
    echo ""
    print_status "🚀 Application Status:"
    kubectl get pods --all-namespaces -l app=sample-web-app
    
    echo ""
    print_status "📈 Monitoring Status:"
    kubectl get pods -n monitoring
    
    echo ""
    print_status "🔒 Security Status:"
    kubectl get pods -n sonarqube
    kubectl get pods -n security
}

# Function to cleanup deployment
cleanup() {
    print_header "Cleaning Up Deployment"
    
    print_warning "This will delete all deployed resources. Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_step "Deleting ArgoCD applications"
        kubectl delete -f "$SCRIPT_DIR/argocd/sample-application.yaml" --ignore-not-found=true
        
        print_step "Deleting sample applications"
        kubectl delete -k "$SCRIPT_DIR/environments/dev/" --ignore-not-found=true
        kubectl delete -k "$SCRIPT_DIR/environments/staging/" --ignore-not-found=true
        kubectl delete -k "$SCRIPT_DIR/environments/prod/" --ignore-not-found=true
        kubectl delete -f "$SCRIPT_DIR/blue-green/blue-deployment.yaml" --ignore-not-found=true
        kubectl delete -f "$SCRIPT_DIR/blue-green/green-deployment.yaml" --ignore-not-found=true
        
        print_step "Deleting Velero"
        kubectl delete -f "$SCRIPT_DIR/backup/velero-install.yaml" --ignore-not-found=true
        kubectl delete -f "$SCRIPT_DIR/backup/backup-schedule.yaml" --ignore-not-found=true
        
        print_step "Deleting monitoring stack"
        kubectl delete -f "$SCRIPT_DIR/monitoring/prometheus-deployment.yaml" --ignore-not-found=true
        kubectl delete -f "$SCRIPT_DIR/monitoring/grafana-deployment.yaml" --ignore-not-found=true
        
        print_step "Deleting security tools"
        kubectl delete -f "$SCRIPT_DIR/security/sonarqube-deployment.yaml" --ignore-not-found=true
        kubectl delete -f "$SCRIPT_DIR/security/trivy-scan-job.yaml" --ignore-not-found=true
        
        print_step "Deleting Jenkins"
        kubectl delete -f "$SCRIPT_DIR/jenkins/jenkins-deployment.yaml" --ignore-not-found=true
        
        print_step "Deleting ArgoCD"
        kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true
        
        print_step "Deleting namespaces"
        for namespace in "${NAMESPACES[@]}"; do
            kubectl delete namespace $namespace --ignore-not-found=true
        done
        
        print_success "Cleanup completed"
    else
        print_status "Cleanup cancelled"
    fi
}

# Main deployment function
deploy_all() {
    print_header "Complete DevOps Pipeline Integration Deployment"
    
    check_prerequisites
    create_namespaces
    deploy_argocd
    deploy_jenkins
    deploy_sonarqube
    deploy_trivy
    deploy_monitoring
    deploy_velero
    deploy_applications
    deploy_argocd_apps
    
    print_header "Deployment Completed Successfully!"
    
    get_access_info
    show_status
    
    echo ""
    print_success "🎉 Complete DevOps Pipeline Integration is now deployed!"
    print_status "📚 Next steps:"
    echo "   1. Access the UIs using the information above"
    echo "   2. Configure your Git repositories in ArgoCD"
    echo "   3. Set up Jenkins pipelines"
    echo "   4. Configure monitoring dashboards"
    echo "   5. Test backup and restore procedures"
    echo ""
    print_status "📖 For detailed instructions, see the documentation in the docs/ directory"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy_all
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup
        ;;
    argocd)
        deploy_argocd
        ;;
    jenkins)
        deploy_jenkins
        ;;
    sonarqube)
        deploy_sonarqube
        ;;
    monitoring)
        deploy_monitoring
        ;;
    velero)
        deploy_velero
        ;;
    apps)
        deploy_applications
        ;;
    *)
        echo "Usage: $0 {deploy|status|cleanup|argocd|jenkins|sonarqube|monitoring|velero|apps}"
        echo ""
        echo "Commands:"
        echo "  deploy      - Deploy the complete DevOps pipeline (default)"
        echo "  status      - Show deployment status"
        echo "  cleanup     - Clean up all deployed resources"
        echo "  argocd      - Deploy only ArgoCD"
        echo "  jenkins     - Deploy only Jenkins"
        echo "  sonarqube   - Deploy only SonarQube"
        echo "  monitoring  - Deploy only monitoring stack"
        echo "  velero      - Deploy only Velero"
        echo "  apps        - Deploy only sample applications"
        exit 1
        ;;
esac
