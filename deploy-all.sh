#!/bin/bash

# Complete DevOps Pipeline Integration - Deploy All Script
# This script provides easy commands for managing the entire DevOps pipeline
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
LOG_FILE="$SCRIPT_DIR/deploy.log"
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

# Function to deploy everything
deploy_all() {
    print_header "Deploying Complete DevOps Pipeline"
    
    # Initialize log file
    echo "DevOps Pipeline Deployment Log - $TIMESTAMP" > "$LOG_FILE"
    
    # Detect OS and AWS
    detect_os
    detect_aws
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy using final-setup.sh
    print_step "Running final setup script..."
    "$SCRIPT_DIR/final-setup.sh"
    
    print_success "Complete DevOps Pipeline deployed successfully!"
    log_message "Deployment completed successfully"
}

# Function to show status
show_status() {
    print_header "DevOps Pipeline Status"
    
    print_info "📊 Namespace Status:"
    kubectl get namespaces | grep -E "(argocd|jenkins|sonarqube|security|monitoring|velero|sample-app)" || print_warning "Some namespaces not found"
    
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
    
    echo ""
    print_info "🔗 Access URLs:"
    echo "   ArgoCD: https://localhost:8080 (admin/[password])"
    echo "   Jenkins: http://localhost:8081 (admin/[password])"
    echo "   SonarQube: http://localhost:9000 (admin/admin)"
    echo "   Prometheus: http://localhost:9090"
    echo "   Grafana: http://localhost:3000 (admin/admin)"
    
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

# Function to cleanup
cleanup() {
    print_header "Cleanup DevOps Pipeline"
    
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

# Function to test components
test_components() {
    print_header "Testing DevOps Pipeline Components"
    
    print_step "Testing ArgoCD..."
    if kubectl get pods -n argocd | grep -q "Running"; then
        print_success "ArgoCD is running"
    else
        print_warning "ArgoCD is not running"
    fi
    
    print_step "Testing Jenkins..."
    if kubectl get pods -n jenkins | grep -q "Running"; then
        print_success "Jenkins is running"
    else
        print_warning "Jenkins is not running"
    fi
    
    print_step "Testing SonarQube..."
    if kubectl get pods -n sonarqube | grep -q "Running"; then
        print_success "SonarQube is running"
    else
        print_warning "SonarQube is not running"
    fi
    
    print_step "Testing Monitoring..."
    if kubectl get pods -n monitoring | grep -q "Running"; then
        print_success "Monitoring stack is running"
    else
        print_warning "Monitoring stack is not running"
    fi
    
    print_step "Testing Velero..."
    if kubectl get pods -n velero | grep -q "Running"; then
        print_success "Velero is running"
    else
        print_warning "Velero is not running"
    fi
    
    print_step "Testing Sample Applications..."
    if kubectl get pods --all-namespaces | grep -q "sample-app"; then
        print_success "Sample applications are running"
    else
        print_warning "Sample applications are not running"
    fi
    
    print_success "Component testing completed"
    log_message "Component testing completed"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy        - Deploy complete DevOps pipeline"
    echo "  status        - Show deployment status"
    echo "  test          - Test all components"
    echo "  cleanup       - Remove all deployed resources"
    echo "  install-tools - Install required tools"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 status"
    echo "  $0 test"
    echo "  $0 cleanup"
}

# Main function
main() {
    case "${1:-}" in
        deploy)
            deploy_all
            ;;
        status)
            show_status
            ;;
        test)
            test_components
            ;;
        cleanup)
            cleanup
            ;;
        install-tools)
            install_tools
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
