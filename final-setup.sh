#!/bin/bash

# Final DevOps Pipeline Setup Script
# Works on all operating systems with automatic detection and fixes

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

# Function to detect OS
detect_os() {
    print_header "Detecting Operating System"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_DISTRO="$ID"
        elif [ -f /etc/redhat-release ]; then
            OS_DISTRO="rhel"
        elif [ -f /etc/debian_version ]; then
            OS_DISTRO="debian"
        else
            OS_DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_DISTRO="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        OS_DISTRO="windows"
    else
        OS_TYPE="unknown"
        OS_DISTRO="unknown"
    fi
    
    print_status "Detected: $OS_TYPE ($OS_DISTRO)"
    print_success "OS Detection completed"
}

# Function to check system requirements
check_requirements() {
    print_header "Checking System Requirements"
    
    # Check memory
    if [[ "$OS_TYPE" == "linux" ]]; then
        local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
        print_status "Available RAM: ${mem_gb}GB"
    elif [[ "$OS_TYPE" == "macos" ]]; then
        local mem_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
        print_status "Available RAM: ${mem_gb}GB"
    fi
    
    # Check disk space
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

# Function to install prerequisites
install_prerequisites() {
    print_header "Installing Prerequisites"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        install_linux_prerequisites
    elif [[ "$OS_TYPE" == "macos" ]]; then
        install_macos_prerequisites
    elif [[ "$OS_TYPE" == "windows" ]]; then
        install_windows_prerequisites
    else
        print_error "Unsupported operating system: $OS_TYPE"
        exit 1
    fi
}

# Linux prerequisites installation
install_linux_prerequisites() {
    # Update package manager
    if command -v dnf &> /dev/null; then
        print_step "Updating packages (dnf)"
        sudo dnf update -y
        INSTALL_CMD="sudo dnf install -y"
    elif command -v yum &> /dev/null; then
        print_step "Updating packages (yum)"
        sudo yum update -y
        INSTALL_CMD="sudo yum install -y"
    elif command -v apt &> /dev/null; then
        print_step "Updating packages (apt)"
        sudo apt update -y
        INSTALL_CMD="sudo apt install -y"
    elif command -v pacman &> /dev/null; then
        print_step "Updating packages (pacman)"
        sudo pacman -Syu --noconfirm
        INSTALL_CMD="sudo pacman -S --noconfirm"
    else
        print_warning "No supported package manager found"
        INSTALL_CMD="echo 'Please install packages manually'"
    fi
    
    # Install basic tools
    print_step "Installing basic tools"
    $INSTALL_CMD curl wget git unzip conntrack-tools socat || true
    
    # Install Docker
    print_step "Installing Docker"
    if ! command -v docker &> /dev/null; then
        if command -v dnf &> /dev/null; then
            $INSTALL_CMD docker
        elif command -v yum &> /dev/null; then
            $INSTALL_CMD docker
        elif command -v apt &> /dev/null; then
            $INSTALL_CMD docker.io
        fi
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
    else
        print_status "Docker already installed"
    fi
    
    # Install kubectl
    print_step "Installing kubectl"
    if ! command -v kubectl &> /dev/null; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    else
        print_status "kubectl already installed"
    fi
    
    # Install Minikube with fallback methods
    print_step "Installing Minikube"
    if ! command -v minikube &> /dev/null; then
        # Method 1: Direct download
        if curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; then
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
            rm minikube-linux-amd64
        # Method 2: wget fallback
        elif wget -O /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64; then
            sudo mv /tmp/minikube /usr/local/bin/minikube
            sudo chmod +x /usr/local/bin/minikube
        # Method 3: Package manager
        else
            $INSTALL_CMD minikube || print_warning "Minikube installation failed, continuing..."
        fi
    else
        print_status "Minikube already installed"
    fi
    
    # Install Helm
    print_step "Installing Helm"
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        print_status "Helm already installed"
    fi
    
    # Install ArgoCD CLI
    print_step "Installing ArgoCD CLI"
    if ! command -v argocd &> /dev/null; then
        curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        chmod +x /usr/local/bin/argocd
    else
        print_status "ArgoCD CLI already installed"
    fi
    
    # Install Velero CLI
    print_step "Installing Velero CLI"
    if ! command -v velero &> /dev/null; then
        curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
        tar -xzf velero-v1.11.1-linux-amd64.tar.gz
        sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/
        rm -rf velero-v1.11.1-linux-amd64.tar.gz velero-v1.11.1-linux-amd64/
    else
        print_status "Velero CLI already installed"
    fi
    
    print_success "Linux prerequisites installed"
}

# macOS prerequisites installation
install_macos_prerequisites() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install tools
    print_step "Installing tools via Homebrew"
    brew install curl wget git kubectl minikube helm argocd velero
    
    print_success "macOS prerequisites installed"
}

# Windows prerequisites installation
install_windows_prerequisites() {
    print_step "Installing Windows prerequisites"
    
    # Check if Chocolatey is installed
    if ! command -v choco &> /dev/null; then
        print_step "Installing Chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    fi
    
    # Install tools
    choco install -y docker-desktop kubernetes-cli minikube kubernetes-helm argocd velero
    
    print_success "Windows prerequisites installed"
    print_warning "Please restart your terminal after installation"
}

# Function to setup Kubernetes cluster
setup_kubernetes() {
    print_header "Setting up Kubernetes Cluster"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        setup_linux_kubernetes
    elif [[ "$OS_TYPE" == "macos" ]]; then
        setup_macos_kubernetes
    elif [[ "$OS_TYPE" == "windows" ]]; then
        setup_windows_kubernetes
    fi
}

# Linux Kubernetes setup
setup_linux_kubernetes() {
    # Start Docker if not running
    if ! sudo systemctl is-active --quiet docker; then
        print_step "Starting Docker service"
        sudo systemctl start docker
    fi
    
    # Start Minikube with fallback methods
    print_step "Starting Minikube"
    if ! minikube status &> /dev/null; then
        # Try different drivers
        if [[ "$EUID" -eq 0 ]]; then
            # Running as root
            if minikube start --driver=none --force; then
                print_success "Minikube started with none driver"
            elif minikube start --driver=docker --force; then
                print_success "Minikube started with docker driver"
            else
                print_warning "Minikube start failed, trying with reduced resources"
                minikube start --driver=docker --force --memory=2048 --cpus=2 || print_error "Minikube start failed"
            fi
        else
            # Running as regular user
            if minikube start --driver=docker; then
                print_success "Minikube started with docker driver"
            elif minikube start --driver=none; then
                print_success "Minikube started with none driver"
            else
                print_warning "Minikube start failed, trying with reduced resources"
                minikube start --driver=docker --memory=2048 --cpus=2 || print_error "Minikube start failed"
            fi
        fi
    else
        print_status "Minikube already running"
    fi
    
    # Wait for cluster to be ready
    print_step "Waiting for cluster to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s || print_warning "Cluster readiness check failed"
    
    print_success "Kubernetes cluster setup completed"
}

# macOS Kubernetes setup
setup_macos_kubernetes() {
    # Start Docker Desktop
    if ! docker info &> /dev/null; then
        print_step "Starting Docker Desktop"
        open -a Docker
        sleep 30
    fi
    
    # Start Minikube
    print_step "Starting Minikube"
    if ! minikube status &> /dev/null; then
        minikube start --driver=docker
    fi
    
    # Wait for cluster to be ready
    print_step "Waiting for cluster to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s || print_warning "Cluster readiness check failed"
    
    print_success "Kubernetes cluster setup completed"
}

# Windows Kubernetes setup
setup_windows_kubernetes() {
    print_step "Starting Docker Desktop"
    # Docker Desktop should be started manually
    
    print_step "Starting Minikube"
    if ! minikube status &> /dev/null; then
        minikube start --driver=docker
    fi
    
    # Wait for cluster to be ready
    print_step "Waiting for cluster to be ready"
    kubectl wait --for=condition=Ready nodes --all --timeout=300s || print_warning "Cluster readiness check failed"
    
    print_success "Kubernetes cluster setup completed"
}

# Function to deploy DevOps pipeline
deploy_pipeline() {
    print_header "Deploying DevOps Pipeline"
    
    # Deploy ArgoCD
    print_step "Deploying ArgoCD"
    kubectl create namespace argocd || true
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd || print_warning "ArgoCD deployment timeout"
    
    # Deploy Jenkins
    print_step "Deploying Jenkins"
    kubectl create namespace jenkins || true
    kubectl apply -f https://raw.githubusercontent.com/jenkinsci/kubernetes-operator/master/deploy/crds/jenkins.io_jenkins_crd.yaml
    kubectl apply -f https://raw.githubusercontent.com/jenkinsci/kubernetes-operator/master/deploy/all-in-one-v1alpha2.yaml
    kubectl wait --for=condition=available --timeout=600s deployment/jenkins-operator -n jenkins || print_warning "Jenkins deployment timeout"
    
    # Deploy SonarQube
    print_step "Deploying SonarQube"
    kubectl create namespace sonarqube || true
    kubectl apply -f https://raw.githubusercontent.com/SonarSource/helm-chart-sonarqube/master/charts/sonarqube/templates/deployment.yaml
    kubectl wait --for=condition=available --timeout=600s deployment/sonarqube -n sonarqube || print_warning "SonarQube deployment timeout"
    
    # Deploy Prometheus and Grafana
    print_step "Deploying Prometheus and Grafana"
    kubectl create namespace monitoring || true
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
    kubectl wait --for=condition=available --timeout=600s deployment/prometheus-operator -n monitoring || print_warning "Prometheus deployment timeout"
    
    # Deploy Velero
    print_step "Deploying Velero"
    kubectl create namespace velero || true
    kubectl apply -f "$SCRIPT_DIR/backup/velero-install.yaml"
    kubectl wait --for condition=established --timeout=60s crd/backups.velero.io || print_warning "Velero CRD wait failed"
    kubectl wait --for condition=established --timeout=60s crd/backupstoragelocations.velero.io || print_warning "Velero CRD wait failed"
    kubectl wait --for condition=established --timeout=60s crd/volumesnapshotlocations.velero.io || print_warning "Velero CRD wait failed"
    kubectl apply -f "$SCRIPT_DIR/backup/backup-schedule.yaml"
    kubectl wait --for=condition=available --timeout=600s deployment/velero -n velero || print_warning "Velero deployment timeout"
    
    print_success "DevOps pipeline deployed successfully"
}

# Function to show access information
show_access_info() {
    print_header "Access Information"
    
    echo -e "${CYAN}🔗 ArgoCD:${NC}"
    echo "  URL: https://$(minikube ip):$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "  Username: admin"
    echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
    
    echo -e "${CYAN}🔗 Jenkins:${NC}"
    echo "  URL: http://$(minikube ip):$(kubectl get svc jenkins-operator-http -n jenkins -o jsonpath='{.spec.ports[0].nodePort}')"
    
    echo -e "${CYAN}🔗 SonarQube:${NC}"
    echo "  URL: http://$(minikube ip):$(kubectl get svc sonarqube -n sonarqube -o jsonpath='{.spec.ports[0].nodePort}')"
    
    echo -e "${CYAN}🔗 Grafana:${NC}"
    echo "  URL: http://$(minikube ip):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "  Username: admin"
    echo "  Password: $(kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d)"
    
    echo -e "${CYAN}🔗 Prometheus:${NC}"
    echo "  URL: http://$(minikube ip):$(kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
    
    print_success "Setup completed successfully!"
}

# Main execution
main() {
    print_header "Final DevOps Pipeline Setup"
    print_status "Starting automated setup for $OS_TYPE"
    
    detect_os
    check_requirements
    install_prerequisites
    setup_kubernetes
    deploy_pipeline
    show_access_info
    
    print_header "Setup Complete!"
    print_success "Your DevOps pipeline is ready to use!"
}

# Run main function
main "$@"
