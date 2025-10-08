#!/bin/bash

# Smart DevOps Pipeline Setup Script
# Automatically detects OS and sets up complete DevOps pipeline
# Supports: Linux, Ubuntu, Windows (WSL2), macOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
OS_TYPE=""
OS_DISTRO=""
PACKAGE_MANAGER=""
INSTALL_COMMAND=""
UPDATE_COMMAND=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup.log"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date): [INFO] $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date): [WARNING] $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date): [ERROR] $1" >> "$LOG_FILE"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
    echo "$(date): [STEP] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date): [SUCCESS] $1" >> "$LOG_FILE"
}

print_os_info() {
    echo -e "${CYAN}[OS-INFO]${NC} $1"
    echo "$(date): [OS-INFO] $1" >> "$LOG_FILE"
}

# Function to detect operating system
detect_os() {
    print_header "Detecting Operating System"
    
    # Detect OS type
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        print_os_info "Detected: Linux"
        
        # Detect Linux distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_DISTRO=$ID
            print_os_info "Distribution: $PRETTY_NAME"
        elif [ -f /etc/redhat-release ]; then
            OS_DISTRO="rhel"
            print_os_info "Distribution: Red Hat Enterprise Linux"
        elif [ -f /etc/debian_version ]; then
            OS_DISTRO="debian"
            print_os_info "Distribution: Debian"
        else
            OS_DISTRO="unknown"
            print_warning "Unknown Linux distribution"
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_DISTRO="macos"
        print_os_info "Detected: macOS"
        
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        OS_DISTRO="windows"
        print_os_info "Detected: Windows"
        
    else
        OS_TYPE="unknown"
        OS_DISTRO="unknown"
        print_error "Unknown operating system: $OSTYPE"
        exit 1
    fi
    
    # Set package manager and commands based on OS
    case $OS_DISTRO in
        "ubuntu"|"debian")
            PACKAGE_MANAGER="apt"
            UPDATE_COMMAND="sudo apt update"
            INSTALL_COMMAND="sudo apt install -y"
            ;;
        "rhel"|"centos"|"fedora"|"amzn")
            PACKAGE_MANAGER="dnf"
            UPDATE_COMMAND="sudo dnf update -y"
            INSTALL_COMMAND="sudo dnf install -y"
            ;;
        "macos")
            PACKAGE_MANAGER="brew"
            UPDATE_COMMAND="brew update"
            INSTALL_COMMAND="brew install"
            ;;
        "windows")
            PACKAGE_MANAGER="choco"
            UPDATE_COMMAND="choco upgrade all -y"
            INSTALL_COMMAND="choco install -y"
            ;;
        *)
            print_warning "Unknown distribution, using generic commands"
            PACKAGE_MANAGER="unknown"
            UPDATE_COMMAND="echo 'Please update your system manually'"
            INSTALL_COMMAND="echo 'Please install packages manually'"
            ;;
    esac
    
    print_success "OS Detection completed: $OS_TYPE ($OS_DISTRO)"
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check available memory
    if [[ "$OS_TYPE" == "linux" ]]; then
        local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
        print_status "Available RAM: ${mem_gb}GB"
        if [ "$mem_gb" -lt 4 ]; then
            print_warning "Recommended: At least 4GB RAM (you have ${mem_gb}GB)"
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        local mem_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
        print_status "Available RAM: ${mem_gb}GB"
        if [ "$mem_gb" -lt 4 ]; then
            print_warning "Recommended: At least 4GB RAM (you have ${mem_gb}GB)"
        fi
    fi
    
    # Check available disk space
    local disk_space=$(df -h . | awk 'NR==2{print $4}')
    print_status "Available disk space: $disk_space"
    
    # Check CPU cores
    if [[ "$OS_TYPE" == "linux" ]]; then
        local cpu_cores=$(nproc)
        print_status "CPU cores: $cpu_cores"
    elif [[ "$OS_TYPE" == "macos" ]]; then
        local cpu_cores=$(sysctl -n hw.ncpu)
        print_status "CPU cores: $cpu_cores"
    fi
    
    print_success "System requirements check completed"
}

# Function to install prerequisites based on OS
install_prerequisites() {
    print_header "Installing Prerequisites"
    
    case $OS_DISTRO in
        "ubuntu"|"debian")
            install_ubuntu_prerequisites
            ;;
        "rhel"|"centos"|"fedora"|"amzn")
            install_rhel_prerequisites
            ;;
        "macos")
            install_macos_prerequisites
            ;;
        "windows")
            install_windows_prerequisites
            ;;
        *)
            print_error "Cannot install prerequisites for unknown OS: $OS_DISTRO"
            exit 1
            ;;
    esac
}

# Ubuntu/Debian specific installation
install_ubuntu_prerequisites() {
    print_step "Installing prerequisites for Ubuntu/Debian"
    
    # Update package list
    $UPDATE_COMMAND
    
    # Install basic tools
    $INSTALL_COMMAND curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Install Docker
    print_step "Installing Docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    $UPDATE_COMMAND
    $INSTALL_COMMAND docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    # Install kubectl
    print_step "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    # Install Minikube
    print_step "Installing Minikube"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    # Install Helm
    print_step "Installing Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install ArgoCD CLI
    print_step "Installing ArgoCD CLI"
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
    
    # Install Velero CLI
    print_step "Installing Velero CLI"
    curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
    tar -xzf velero-v1.11.1-linux-amd64.tar.gz
    sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/
    rm -rf velero-v1.11.1-linux-amd64.tar.gz velero-v1.11.1-linux-amd64/
    
    print_success "Ubuntu/Debian prerequisites installed"
}

# RHEL/CentOS/Fedora/Amazon Linux specific installation
install_rhel_prerequisites() {
    print_step "Installing prerequisites for RHEL/CentOS/Fedora/Amazon Linux"
    
    # Update packages
    $UPDATE_COMMAND
    
    # Install basic tools
    $INSTALL_COMMAND curl wget git unzip
    
    # Install Docker
    print_step "Installing Docker"
    $INSTALL_COMMAND docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    if [[ "$OS_DISTRO" == "amzn" ]]; then
        sudo usermod -aG docker ec2-user
    else
        sudo usermod -aG docker $USER
    fi
    
    # Install kubectl
    print_step "Installing kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    # Install Minikube
    print_step "Installing Minikube"
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    # Install Helm
    print_step "Installing Helm"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install ArgoCD CLI
    print_step "Installing ArgoCD CLI"
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
    
    # Install Velero CLI
    print_step "Installing Velero CLI"
    curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
    tar -xzf velero-v1.11.1-linux-amd64.tar.gz
    sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/
    rm -rf velero-v1.11.1-linux-amd64.tar.gz velero-v1.11.1-linux-amd64/
    
    print_success "RHEL/CentOS/Fedora/Amazon Linux prerequisites installed"
}

# macOS specific installation
install_macos_prerequisites() {
    print_step "Installing prerequisites for macOS"
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Update Homebrew
    $UPDATE_COMMAND
    
    # Install basic tools
    $INSTALL_COMMAND curl wget git
    
    # Install Docker Desktop
    print_step "Installing Docker Desktop"
    $INSTALL_COMMAND --cask docker
    
    # Install kubectl
    print_step "Installing kubectl"
    $INSTALL_COMMAND kubernetes-cli
    
    # Install Minikube
    print_step "Installing Minikube"
    $INSTALL_COMMAND minikube
    
    # Install Helm
    print_step "Installing Helm"
    $INSTALL_COMMAND helm
    
    # Install ArgoCD CLI
    print_step "Installing ArgoCD CLI"
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
    chmod +x /usr/local/bin/argocd
    
    # Install Velero CLI
    print_step "Installing Velero CLI"
    curl -fsSL -o velero-v1.11.1-darwin-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-darwin-amd64.tar.gz
    tar -xzf velero-v1.11.1-darwin-amd64.tar.gz
    sudo mv velero-v1.11.1-darwin-amd64/velero /usr/local/bin/
    rm -rf velero-v1.11.1-darwin-amd64.tar.gz velero-v1.11.1-darwin-amd64/
    
    print_success "macOS prerequisites installed"
}

# Windows specific installation
install_windows_prerequisites() {
    print_step "Installing prerequisites for Windows"
    
    # Check if Chocolatey is installed
    if ! command -v choco &> /dev/null; then
        print_step "Installing Chocolatey"
        print_warning "Please run the following PowerShell commands as Administrator:"
        echo "Set-ExecutionPolicy Bypass -Scope Process -Force"
        echo "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072"
        echo "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        print_warning "After installing Chocolatey, run this script again"
        return 1
    fi
    
    # Update Chocolatey
    choco upgrade all -y
    
    # Install basic tools
    choco install -y git curl wget
    
    # Install Docker Desktop
    print_step "Installing Docker Desktop"
    choco install -y docker-desktop
    
    # Install kubectl
    print_step "Installing kubectl"
    choco install -y kubernetes-cli
    
    # Install Minikube
    print_step "Installing Minikube"
    choco install -y minikube
    
    # Install Helm
    print_step "Installing Helm"
    choco install -y kubernetes-helm
    
    # Install ArgoCD CLI
    print_step "Installing ArgoCD CLI"
    choco install -y argocd
    
    # Install Velero CLI
    print_step "Installing Velero CLI"
    choco install -y velero
    
    print_success "Windows prerequisites installed"
    print_warning "Please restart your terminal/PowerShell after installation"
}

# Function to setup Kubernetes cluster
setup_kubernetes_cluster() {
    print_header "Setting up Kubernetes Cluster"
    
    case $OS_DISTRO in
        "ubuntu"|"debian"|"rhel"|"centos"|"fedora"|"amzn")
            setup_linux_kubernetes
            ;;
        "macos")
            setup_macos_kubernetes
            ;;
        "windows")
            setup_windows_kubernetes
            ;;
        *)
            print_error "Cannot setup Kubernetes for unknown OS: $OS_DISTRO"
            exit 1
            ;;
    esac
}

# Linux Kubernetes setup
setup_linux_kubernetes() {
    print_step "Starting Minikube cluster"
    
    # Start Minikube with appropriate resources
    minikube start --memory=8192 --cpus=4 --driver=docker
    
    # Verify cluster is running
    minikube status
    
    # Configure kubectl
    kubectl cluster-info
    
    print_success "Kubernetes cluster setup completed"
}

# macOS Kubernetes setup
setup_macos_kubernetes() {
    print_step "Starting Minikube cluster"
    
    # Start Minikube with appropriate resources
    minikube start --memory=8192 --cpus=4 --driver=docker
    
    # Verify cluster is running
    minikube status
    
    # Configure kubectl
    kubectl cluster-info
    
    print_success "Kubernetes cluster setup completed"
}

# Windows Kubernetes setup
setup_windows_kubernetes() {
    print_step "Starting Minikube cluster"
    
    # Start Minikube with appropriate resources
    minikube start --memory=8192 --cpus=4 --driver=docker
    
    # Verify cluster is running
    minikube status
    
    # Configure kubectl
    kubectl cluster-info
    
    print_success "Kubernetes cluster setup completed"
}

# Function to verify installation
verify_installation() {
    print_header "Verifying Installation"
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_status "✅ Docker: $(docker --version)"
    else
        print_error "❌ Docker not found"
    fi
    
    # Check kubectl
    if command -v kubectl &> /dev/null; then
        print_status "✅ kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Installed')"
    else
        print_error "❌ kubectl not found"
    fi
    
    # Check Minikube
    if command -v minikube &> /dev/null; then
        print_status "✅ Minikube: $(minikube version --short 2>/dev/null || echo 'Installed')"
    else
        print_error "❌ Minikube not found"
    fi
    
    # Check Helm
    if command -v helm &> /dev/null; then
        print_status "✅ Helm: $(helm version --short 2>/dev/null || echo 'Installed')"
    else
        print_error "❌ Helm not found"
    fi
    
    # Check ArgoCD CLI
    if command -v argocd &> /dev/null; then
        print_status "✅ ArgoCD CLI: $(argocd version --client --short 2>/dev/null || echo 'Installed')"
    else
        print_error "❌ ArgoCD CLI not found"
    fi
    
    # Check Velero CLI
    if command -v velero &> /dev/null; then
        print_status "✅ Velero CLI: $(velero version --client --short 2>/dev/null || echo 'Installed')"
    else
        print_error "❌ Velero CLI not found"
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        print_status "✅ Git: $(git --version)"
    else
        print_error "❌ Git not found"
    fi
    
    print_success "Installation verification completed"
}

# Function to deploy DevOps pipeline
deploy_devops_pipeline() {
    print_header "Deploying DevOps Pipeline"
    
    # Make scripts executable
    print_step "Making scripts executable"
    chmod +x "$SCRIPT_DIR"/*.sh
    chmod +x "$SCRIPT_DIR"/*/*.sh
    
    # Deploy the complete pipeline
    print_step "Deploying complete DevOps pipeline"
    "$SCRIPT_DIR/deploy-all.sh"
    
    print_success "DevOps pipeline deployment completed"
}

# Function to show access information
show_access_info() {
    print_header "Access Information"
    
    echo ""
    print_status "🔗 ArgoCD UI:"
    echo "   URL: https://localhost:8080"
    echo "   Username: admin"
    echo "   Password: Check ArgoCD namespace for initial admin secret"
    echo ""
    
    print_status "🔗 Jenkins UI:"
    echo "   URL: http://localhost:8081"
    echo "   Username: admin"
    echo "   Password: Check Jenkins namespace for initial admin password"
    echo ""
    
    print_status "🔗 SonarQube UI:"
    echo "   URL: http://localhost:9000"
    echo "   Username: admin"
    echo "   Password: admin"
    echo ""
    
    print_status "🔗 Prometheus UI:"
    echo "   URL: http://localhost:9090"
    echo ""
    
    print_status "🔗 Grafana UI:"
    echo "   URL: http://localhost:3000"
    echo "   Username: admin"
    echo "   Password: admin"
    echo ""
    
    print_warning "To access the UIs, run these port-forward commands:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   kubectl port-forward svc/jenkins -n jenkins 8081:8080"
    echo "   kubectl port-forward svc/sonarqube -n sonarqube 9000:9000"
    echo "   kubectl port-forward svc/prometheus -n monitoring 9090:9090"
    echo "   kubectl port-forward svc/grafana -n monitoring 3000:3000"
}

# Function to show next steps
show_next_steps() {
    print_header "Next Steps"
    
    echo ""
    print_status "🎉 Setup completed successfully!"
    echo ""
    print_status "📚 What you can do now:"
    echo "   1. Access the web UIs using the information above"
    echo "   2. Configure your Git repositories in ArgoCD"
    echo "   3. Set up Jenkins pipelines for your applications"
    echo "   4. Configure monitoring dashboards in Grafana"
    echo "   5. Test backup and restore procedures with Velero"
    echo "   6. Deploy your own applications using the sample templates"
    echo ""
    print_status "📖 For detailed instructions, see:"
    echo "   - README.md (main documentation)"
    echo "   - docs/ directory (step-by-step guides)"
    echo ""
    print_status "🛠️ Useful commands:"
    echo "   - Check status: ./deploy-all.sh status"
    echo "   - Blue-green deployment: ./blue-green/blue-green-script.sh deploy"
    echo "   - Create backup: ./backup/backup-script.sh create my-backup sample-app-dev"
    echo "   - Cleanup: ./deploy-all.sh cleanup"
    echo ""
    print_status "📝 Setup log saved to: $LOG_FILE"
}

# Main setup function
main_setup() {
    print_header "Smart DevOps Pipeline Setup"
    print_status "Starting automated setup for $OS_TYPE ($OS_DISTRO)"
    
    # Initialize log file
    echo "Smart DevOps Pipeline Setup Log" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "OS: $OS_TYPE ($OS_DISTRO)" >> "$LOG_FILE"
    echo "=================================" >> "$LOG_FILE"
    
    # Run setup steps
    detect_os
    check_system_requirements
    install_prerequisites
    setup_kubernetes_cluster
    verify_installation
    deploy_devops_pipeline
    show_access_info
    show_next_steps
    
    print_success "🎉 Complete DevOps Pipeline setup finished successfully!"
    print_status "Setup log: $LOG_FILE"
}

# Function to show help
show_help() {
    echo "Smart DevOps Pipeline Setup Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup     - Run complete setup (default)"
    echo "  install   - Install prerequisites only"
    echo "  cluster   - Setup Kubernetes cluster only"
    echo "  deploy    - Deploy DevOps pipeline only"
    echo "  verify    - Verify installation"
    echo "  status    - Show deployment status"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Complete setup"
    echo "  $0 install            # Install prerequisites only"
    echo "  $0 cluster            # Setup Kubernetes cluster only"
    echo "  $0 deploy             # Deploy DevOps pipeline only"
    echo "  $0 verify             # Verify installation"
    echo "  $0 status             # Show deployment status"
    echo ""
    echo "Supported Operating Systems:"
    echo "  - Ubuntu/Debian"
    echo "  - RHEL/CentOS/Fedora/Amazon Linux"
    echo "  - macOS"
    echo "  - Windows (with WSL2 or PowerShell)"
    echo ""
    echo "For more information, see README.md"
}

# Main script logic
case "${1:-setup}" in
    setup)
        main_setup
        ;;
    install)
        detect_os
        check_system_requirements
        install_prerequisites
        verify_installation
        ;;
    cluster)
        detect_os
        setup_kubernetes_cluster
        ;;
    deploy)
        deploy_devops_pipeline
        show_access_info
        ;;
    verify)
        verify_installation
        ;;
    status)
        if [ -f "$SCRIPT_DIR/deploy-all.sh" ]; then
            "$SCRIPT_DIR/deploy-all.sh" status
        else
            print_error "deploy-all.sh not found. Please run setup first."
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
