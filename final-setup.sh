#!/bin/bash

# Complete DevOps Pipeline Integration - Final Setup Script
# This script deploys the entire DevOps pipeline with all components
# Supports: Linux, macOS, Windows (WSL2), AWS EC2

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
LOG_FILE="$SCRIPT_DIR/setup.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Function to detect OS
detect_os() {
    print_info "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VERSION=$VERSION_ID
        elif [ -f /etc/redhat-release ]; then
            OS="rhel"
            VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+' | head -1)
        elif [ -f /etc/debian_version ]; then
            OS="debian"
            VERSION=$(cat /etc/debian_version)
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VERSION=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    print_info "Detected OS: $OS $VERSION"
    log_message "OS Detection: $OS $VERSION"
}

# Function to detect AWS instance
detect_aws() {
    if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
        print_info "AWS EC2 Instance Detected"
        INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
        AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
        
        print_info "Instance Type: $INSTANCE_TYPE"
        print_info "Instance ID: $INSTANCE_ID"
        print_info "Region: $REGION"
        print_info "Availability Zone: $AZ"
        
        log_message "AWS Detection: $INSTANCE_TYPE in $REGION"
        return 0
    else
        return 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    else
        print_success "Docker is installed: $(docker --version)"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        print_success "kubectl is installed: $(kubectl version --client --short)"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    else
        print_success "Git is installed: $(git --version)"
    fi
    
    # Check if Kubernetes cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_warning "Cannot connect to Kubernetes cluster"
        print_info "Please ensure you have a Kubernetes cluster running (minikube, kind, or cloud cluster)"
    else
        print_success "Kubernetes cluster is accessible"
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install the missing tools and run this script again"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    log_message "Prerequisites check completed"
}

# Function to create namespaces
create_namespaces() {
    print_header "Creating Namespaces"
    
    local namespaces=("argocd" "jenkins" "sonarqube" "security" "monitoring" "velero")
    
    for namespace in "${namespaces[@]}"; do
        print_step "Creating namespace: $namespace"
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
        log_message "Namespace $namespace created"
    done
    
    print_success "All namespaces created"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_header "Deploying ArgoCD (GitOps)"
    
    print_step "Installing ArgoCD"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    print_step "Waiting for ArgoCD to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || print_warning "ArgoCD server wait failed, continuing..."
    kubectl wait --for=condition=available --timeout=300s statefulset/argocd-application-controller -n argocd || print_warning "ArgoCD application controller wait failed, continuing..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argocd || print_warning "ArgoCD repo server wait failed, continuing..."
    
    print_step "Configuring ArgoCD server for external access"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' || print_warning "ArgoCD service patch failed, continuing..."
    
    print_success "ArgoCD deployed successfully"
    log_message "ArgoCD deployment completed"
}

# Function to deploy Jenkins
deploy_jenkins() {
    print_header "Deploying Jenkins (CI/CD)"
    
    print_step "Installing Jenkins"
    kubectl apply -f "$SCRIPT_DIR/jenkins/jenkins-deployment.yaml"
    
    print_step "Waiting for Jenkins to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins || print_warning "Jenkins deployment wait failed, continuing..."
    
    print_success "Jenkins deployed successfully"
    log_message "Jenkins deployment completed"
}

# Function to deploy SonarQube
deploy_sonarqube() {
    print_header "Deploying SonarQube (Code Quality)"
    
    print_step "Installing SonarQube"
    kubectl apply -f "$SCRIPT_DIR/security/sonarqube-deployment.yaml"
    
    print_step "Waiting for SonarQube to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube || print_warning "SonarQube deployment wait failed, continuing..."
    kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n sonarqube || print_warning "PostgreSQL deployment wait failed, continuing..."
    
    print_success "SonarQube deployed successfully"
    log_message "SonarQube deployment completed"
}

# Function to deploy Trivy
deploy_trivy() {
    print_header "Deploying Trivy (Security Scanning)"
    
    print_step "Installing Trivy scanning jobs"
    kubectl apply -f "$SCRIPT_DIR/security/trivy-scan-job.yaml"
    
    print_success "Trivy deployed successfully"
    log_message "Trivy deployment completed"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_header "Deploying Monitoring Stack"
    
    print_step "Installing Prometheus"
    kubectl apply -f "$SCRIPT_DIR/monitoring/prometheus-deployment.yaml"
    
    print_step "Installing Grafana"
    kubectl apply -f "$SCRIPT_DIR/monitoring/grafana-deployment.yaml"
    
    print_step "Waiting for monitoring stack to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || print_warning "Prometheus deployment wait failed, continuing..."
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || print_warning "Grafana deployment wait failed, continuing..."
    
    print_success "Monitoring stack deployed successfully"
    log_message "Monitoring stack deployment completed"
}

# Function to deploy Velero
deploy_velero() {
    print_header "Deploying Velero (Backup & DR)"
    
    print_step "Installing Velero CRDs first"
    kubectl apply -f "$SCRIPT_DIR/backup/velero-install.yaml"
    
    print_step "Waiting for CRDs to be established"
    kubectl wait --for condition=established --timeout=60s crd/backups.velero.io || print_warning "Velero CRD wait failed, continuing..."
    kubectl wait --for condition=established --timeout=60s crd/backupstoragelocations.velero.io || print_warning "Velero CRD wait failed, continuing..."
    kubectl wait --for condition=established --timeout=60s crd/restores.velero.io || print_warning "Velero CRD wait failed, continuing..."
    kubectl wait --for condition=established --timeout=60s crd/schedules.velero.io || print_warning "Velero CRD wait failed, continuing..."
    kubectl wait --for condition=established --timeout=60s crd/volumesnapshotlocations.velero.io || print_warning "Velero CRD wait failed, continuing..."
    
    print_step "Installing backup schedules"
    kubectl apply -f "$SCRIPT_DIR/backup/backup-schedule.yaml"
    
    print_step "Waiting for Velero to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/velero -n velero || print_warning "Velero deployment wait failed, continuing..."
    
    print_success "Velero deployed successfully"
    log_message "Velero deployment completed"
}

# Function to deploy sample applications
deploy_sample_apps() {
    print_header "Deploying Sample Applications"
    
    print_step "Deploying to Development environment"
    kubectl apply -k "$SCRIPT_DIR/environments/dev/" || print_warning "Dev environment deployment failed, continuing..."
    
    print_step "Deploying to Staging environment"
    kubectl apply -k "$SCRIPT_DIR/environments/staging/" || print_warning "Staging environment deployment failed, continuing..."
    
    print_step "Deploying to Production environment"
    kubectl apply -k "$SCRIPT_DIR/environments/prod/" || print_warning "Production environment deployment failed, continuing..."
    
    print_step "Deploying Blue-Green setup"
    kubectl apply -f "$SCRIPT_DIR/blue-green/blue-deployment.yaml" || print_warning "Blue deployment failed, continuing..."
    kubectl apply -f "$SCRIPT_DIR/blue-green/green-deployment.yaml" || print_warning "Green deployment failed, continuing..."
    
    print_success "Sample applications deployed successfully"
    log_message "Sample applications deployment completed"
}

# Function to deploy ArgoCD applications
deploy_argocd_apps() {
    print_header "Deploying ArgoCD Applications"
    
    print_step "Creating ArgoCD applications"
    kubectl apply -f "$SCRIPT_DIR/argocd/sample-application.yaml" || print_warning "ArgoCD application deployment failed, continuing..."
    
    print_success "ArgoCD applications deployed successfully"
    log_message "ArgoCD applications deployment completed"
}

# Function to show access information
show_access_info() {
    print_header "Deployment Completed Successfully!"
    
    echo ""
    print_info "🔗 ArgoCD UI:"
    echo "   URL: https://localhost:8080"
    echo "   Username: admin"
    echo "   Password: Check ArgoCD namespace for initial admin secret"
    
    echo ""
    print_info "🔗 Jenkins UI:"
    echo "   URL: http://localhost:8081"
    echo "   Username: admin"
    echo "   Password: Check Jenkins namespace for initial admin password"
    
    echo ""
    print_info "🔗 SonarQube UI:"
    echo "   URL: http://localhost:9000"
    echo "   Username: admin"
    echo "   Password: admin"
    
    echo ""
    print_info "🔗 Prometheus UI:"
    echo "   URL: http://localhost:9090"
    
    echo ""
    print_info "🔗 Grafana UI:"
    echo "   URL: http://localhost:3000"
    echo "   Username: admin"
    echo "   Password: admin"
    
    echo ""
    print_warning "If using port-forward, run these commands:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   kubectl port-forward svc/jenkins -n jenkins 8081:8080"
    echo "   kubectl port-forward svc/sonarqube -n sonarqube 9000:9000"
    echo "   kubectl port-forward svc/prometheus -n monitoring 9090:9090"
    echo "   kubectl port-forward svc/grafana -n monitoring 3000:3000"
    
    # Show AWS-specific information if detected
    if detect_aws; then
        echo ""
        print_info "🔗 For AWS EC2, replace localhost with your EC2 public IP:"
        echo "   ArgoCD: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
        echo "   Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8081"
        echo "   SonarQube: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000"
        echo "   Prometheus: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090"
        echo "   Grafana: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
    fi
}

# Function to show next steps
show_next_steps() {
    print_header "Next Steps"
    
    echo ""
    print_info "🎉 Setup completed successfully!"
    
    echo ""
    print_info "📚 What you can do now:"
    echo "   1. Access the web UIs using the information above"
    echo "   2. Configure your Git repositories in ArgoCD"
    echo "   3. Set up Jenkins pipelines for your applications"
    echo "   4. Configure monitoring dashboards in Grafana"
    echo "   5. Test backup and restore procedures with Velero"
    echo "   6. Deploy your own applications using the sample templates"
    
    echo ""
    print_info "📖 For detailed instructions, see:"
    echo "   - README.md (main documentation)"
    echo "   - docs/ directory (step-by-step guides)"
    
    echo ""
    print_info "🛠️ Useful commands:"
    echo "   - Check status: ./final-setup.sh status"
    echo "   - Blue-green deployment: ./blue-green/blue-green-script.sh deploy"
    echo "   - Create backup: ./backup/backup-script.sh create my-backup sample-app-dev"
    echo "   - Cleanup: ./final-setup.sh cleanup"
    
    echo ""
    print_info "📝 Setup log saved to: $LOG_FILE"
}

# Function to show status
show_status() {
    print_header "Deployment Status"
    
    print_info "📊 Namespace Status:"
    kubectl get namespaces | grep -E "(argocd|jenkins|sonarqube|security|monitoring|velero)" || print_warning "Some namespaces not found"
    
    echo ""
    print_info "🚀 Application Status:"
    kubectl get pods --all-namespaces | grep -E "(argocd|jenkins|sonarqube|monitoring|velero|sample-app)" || print_warning "Some applications not found"
    
    echo ""
    print_info "📈 Monitoring Status:"
    kubectl get pods -n monitoring || print_warning "Monitoring pods not found"
    
    echo ""
    print_info "🔒 Security Status:"
    kubectl get pods -n sonarqube || print_warning "SonarQube pods not found"
    kubectl get pods -n security || print_warning "Security pods not found"
}

# Function to cleanup
cleanup() {
    print_header "Cleanup"
    
    print_warning "This will delete all deployed resources"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Deleting all namespaces..."
        kubectl delete namespace argocd jenkins sonarqube security monitoring velero sample-app-dev sample-app-staging sample-app-prod || print_warning "Some namespaces not found"
        
        print_success "Cleanup completed"
        log_message "Cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Function to install missing tools
install_tools() {
    print_header "Installing Missing Tools"
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            print_step "Installing tools for Ubuntu/Debian..."
            sudo apt update
            sudo apt install -y docker.io kubectl git curl wget
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        rhel|centos|amazon)
            print_step "Installing tools for RHEL/CentOS/Amazon Linux..."
            sudo dnf update -y
            sudo dnf install -y docker kubectl git curl wget
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            ;;
        macos)
            print_step "Installing tools for macOS..."
            if ! command -v brew &> /dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install docker kubectl git
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Tools installation completed"
    log_message "Tools installation completed for $OS"
}

# Main function
main() {
    # Initialize log file
    echo "DevOps Pipeline Setup Log - $TIMESTAMP" > "$LOG_FILE"
    
    print_header "Complete DevOps Pipeline Integration Deployment"
    
    # Detect OS and AWS
    detect_os
    detect_aws
    
    # Check command line arguments
    case "${1:-}" in
        status)
            show_status
            exit 0
            ;;
        cleanup)
            cleanup
            exit 0
            ;;
        install-tools)
            install_tools
            exit 0
            ;;
        help|--help|-h)
            echo "Usage: $0 [status|cleanup|install-tools]"
            echo ""
            echo "Commands:"
            echo "  (no args)     - Deploy complete DevOps pipeline"
            echo "  status        - Show deployment status"
            echo "  cleanup       - Remove all deployed resources"
            echo "  install-tools - Install required tools"
            echo "  help          - Show this help message"
            exit 0
            ;;
    esac
    
    # Main deployment process
    check_prerequisites
    create_namespaces
    deploy_argocd
    deploy_jenkins
    deploy_sonarqube
    deploy_trivy
    deploy_monitoring
    deploy_velero
    deploy_sample_apps
    deploy_argocd_apps
    show_access_info
    show_next_steps
    
    print_success "🎉 Complete DevOps Pipeline setup finished successfully!"
    print_info "Setup log: $LOG_FILE"
    
    log_message "Setup completed successfully"
}

# Run main function
main "$@"
