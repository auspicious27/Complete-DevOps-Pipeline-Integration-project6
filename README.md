# Complete DevOps Pipeline Integration

## 🎯 What This Project Does (Simple Explanation)

This project creates a **complete automated system** that helps developers deploy their applications easily and safely. Think of it as a **smart factory** for software:

- **Developer writes code** → **System automatically builds, tests, and deploys it**
- **No manual work needed** → **Everything happens automatically**
- **Safe deployments** → **If something goes wrong, it automatically rolls back**
- **Multiple environments** → **Test in development, then move to production safely**

## 🎯 Project Overview

This project demonstrates a complete, production-ready DevOps pipeline that integrates all major DevOps tools including Docker, Jenkins, Kubernetes, Ansible, Terraform, Monitoring, and GitOps with ArgoCD.

## 🎯 Real-World Use Cases This Project Solves

### Use Case 1: E-commerce Website Deployment
**Problem**: You have an online store and need to update it without customers noticing
**Solution**: This project provides zero-downtime deployment using Blue-Green strategy
**Result**: Customers can shop while you update the website

### Use Case 2: Banking Application Security
**Problem**: Banking apps need to be very secure and pass all security checks
**Solution**: Automated security scanning with Trivy and SonarQube
**Result**: Only secure code gets deployed to production

### Use Case 3: Multi-Team Development
**Problem**: Multiple teams working on different features need separate environments
**Solution**: Multi-environment setup (Dev, Staging, Production)
**Result**: Teams can work independently without affecting each other

### Use Case 4: Disaster Recovery
**Problem**: What if your server crashes and you lose all data?
**Solution**: Automated backup system with Velero
**Result**: You can restore everything in minutes, not hours

### Use Case 5: Monitoring and Alerts
**Problem**: How do you know if your application is working properly?
**Solution**: Prometheus and Grafana monitoring
**Result**: You get alerts before users notice problems

## 🏗️ Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub Repo   │    │   Jenkins CI    │
│                 │───▶│                 │───▶│                 │
│   Git Push      │    │   Source Code   │    │   Build & Test  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ArgoCD        │    │   Helm Charts   │    │   Security      │
│   GitOps        │◀───│   Kustomize     │◀───│   Scanning      │
│   Controller    │    │   Manifests     │    │   Trivy/Sonar   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │   Monitoring    │    │   Backup & DR   │
│   Cluster       │───▶│   Prometheus    │    │   Velero        │
│   (Dev/Stg/Prod)│    │   Grafana       │    │   Backup        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Requirements (What You Need)

### System Requirements
- **Operating System**: Linux, macOS, or Windows with WSL2
- **RAM**: Minimum 8GB, Recommended 16GB
- **CPU**: Minimum 4 cores, Recommended 8 cores
- **Storage**: Minimum 50GB free space
- **Internet**: Stable internet connection
- **Docker**: For container management
- **Kubernetes**: Local cluster (minikube/kind) or cloud cluster

### Simple Requirements Checklist
```bash
# Check if you have everything needed
echo "=== System Requirements Check ==="
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "CPU Cores: $(nproc)"
echo "Disk Space: $(df -h / | awk 'NR==2{print $4}')"
echo "OS: $(uname -s)"
echo "Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Kubernetes: $(kubectl version --client 2>/dev/null || echo 'Not installed')"
echo "Git: $(git --version 2>/dev/null || echo 'Not installed')"

# Expected Output:
# === System Requirements Check ===
# RAM: 16Gi
# CPU Cores: 8
# Disk Space: 200G
# OS: Linux
# Docker: Docker version 24.0.7
# Kubernetes: Client Version: version.Info{Major:"1", Minor:"28"}
# Git: git version 2.34.1
```

### Required Software Installation

#### Step 1: Install Docker
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# RHEL 10 / CentOS Stream
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Amazon Linux 2023
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Windows (PowerShell)
# Install Docker Desktop from: https://www.docker.com/products/docker-desktop
# Or use Chocolatey:
choco install docker-desktop -y

# macOS
brew install docker
brew install --cask docker

# Verify Docker installation
docker --version
docker run hello-world

# Expected Output:
# Docker version 24.0.7, build afdd53b
# Hello from Docker!
```

#### Step 2: Install Kubernetes Cluster (Choose One)
```bash
# Option A: Minikube (Recommended for beginners)
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker
minikube status

# Windows (PowerShell)
# Download from: https://minikube.sigs.k8s.io/docs/start/
# Or use Chocolatey:
choco install minikube -y
minikube start --memory=8192 --cpus=4 --driver=docker

# macOS
brew install minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Expected Output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured

# Option B: Kind (Lightweight alternative)
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind create cluster --name devops-pipeline
kind get clusters

# Windows (PowerShell)
# Download from: https://kind.sigs.k8s.io/docs/user/quick-start/
# Or use Chocolatey:
choco install kind -y
kind create cluster --name devops-pipeline

# macOS
brew install kind
kind create cluster --name devops-pipeline

# Expected Output:
# devops-pipeline
```

#### Step 3: Install kubectl
```bash
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows (PowerShell)
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Or use Chocolatey:
choco install kubernetes-cli -y

# macOS
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify kubectl installation
kubectl version --client
kubectl cluster-info

# Expected Output:
# Client Version: version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.0"}
# Kubernetes control plane is running at https://127.0.0.1:32768
```

#### Step 4: Install Helm
```bash
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows (PowerShell)
# Download from: https://helm.sh/docs/intro/install/
# Or use Chocolatey:
choco install kubernetes-helm -y

# macOS
brew install helm

# Verify Helm installation
helm version

# Expected Output:
# version.BuildInfo{Version:"v3.12.0", GitCommit:"c9f554d75773799f72ceef38c51210f1842a1dea"}
```

#### Step 5: Install ArgoCD CLI
```bash
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Windows (PowerShell)
# Download from: https://argo-cd.readthedocs.io/en/stable/cli_installation/
# Or use Chocolatey:
choco install argocd -y

# macOS
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
chmod +x /usr/local/bin/argocd

# Verify ArgoCD CLI installation
argocd version --client

# Expected Output:
# argocd: v2.8.4+unknown
```

#### Step 6: Install Velero CLI
```bash
# Linux (Ubuntu/Debian/RHEL/Amazon Linux)
curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
tar -xzf velero-v1.11.1-linux-amd64.tar.gz
sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/

# Windows (PowerShell)
# Download from: https://velero.io/docs/main/basic-install/
# Or use Chocolatey:
choco install velero -y

# macOS
curl -fsSL -o velero-v1.11.1-darwin-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-darwin-amd64.tar.gz
tar -xzf velero-v1.11.1-darwin-amd64.tar.gz
sudo mv velero-v1.11.1-darwin-amd64/velero /usr/local/bin/

# Verify Velero CLI installation
velero version --client

# Expected Output:
# Client: v1.11.1
```

#### Step 7: Install Git
```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install git -y

# RHEL 10 / CentOS Stream
sudo dnf install -y git

# Amazon Linux 2023
sudo dnf install -y git

# Windows (PowerShell)
# Download from: https://git-scm.com/download/win
# Or use Chocolatey:
choco install git -y

# macOS
brew install git

# Verify Git installation
git --version

# Expected Output:
# git version 2.34.1
```

### Verify Installation
```bash
# Check if all tools are installed
kubectl version --client
helm version
argocd version --client
velero version --client
git --version

# Expected Output:
# Client Version: version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.0"}
# version.BuildInfo{Version:"v3.12.0", GitCommit:"c9f554d75773799f72ceef38c51210f1842a1dea"}
# argocd: v2.8.4+unknown
# Client: v1.11.1
# git version 2.34.1
```

## 🚀 How to Run This Project

### Method 1: One-Command Deployment (Easiest)
```bash
# Step 1: Clone the repository
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6

# Step 2: Make scripts executable
chmod +x *.sh
chmod +x */*.sh

# Step 3: Run the complete deployment
./deploy-all.sh

# Expected Output: Complete pipeline deployed in 5-10 minutes
```

### Method 2: Step-by-Step Manual Deployment
```bash
# Step 1: Clone and setup
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6

# Step 2: Install requirements (if not already installed)
# Follow the "Required Software Installation" section above

# Step 3: Deploy each component manually
# Follow the "Manual Step-by-Step Deployment" section above

# Expected Output: Complete control over each component
```

### Method 3: Docker Desktop (Windows/Mac Users)
```bash
# Step 1: Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Step 2: Enable Kubernetes in Docker Desktop
# Go to Settings > Kubernetes > Enable Kubernetes

# Step 3: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
./deploy-all.sh

# Expected Output: Works on Windows and Mac without additional setup
```

### Method 4: Cloud Kubernetes (AWS/GCP/Azure)
```bash
# Step 1: Create Kubernetes cluster on your cloud provider
# AWS: eksctl create cluster --name devops-pipeline
# GCP: gcloud container clusters create devops-pipeline
# Azure: az aks create --name devops-pipeline --resource-group myResourceGroup

# Step 2: Configure kubectl to connect to your cluster
# AWS: aws eks update-kubeconfig --region us-west-2 --name devops-pipeline
# GCP: gcloud container clusters get-credentials devops-pipeline
# Azure: az aks get-credentials --resource-group myResourceGroup --name devops-pipeline

# Step 3: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
./deploy-all.sh

# Expected Output: Production-ready deployment on cloud
```

### Method 5: Local Development with Minikube
```bash
# Step 1: Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Step 2: Start Minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Step 3: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
./deploy-all.sh

# Expected Output: Local Kubernetes cluster with full pipeline
```

### Method 6: Kind (Kubernetes in Docker)
```bash
# Step 1: Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Step 2: Create Kind cluster
kind create cluster --name devops-pipeline

# Step 3: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
./deploy-all.sh

# Expected Output: Lightweight Kubernetes cluster
```

### Method 7: RHEL 10 / CentOS Stream
```bash
# Step 1: Install required packages
sudo dnf update -y
sudo dnf install -y curl wget git docker

# Step 2: Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Step 3: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Step 4: Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Step 5: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh && chmod +x */*.sh
./deploy-all.sh

# Expected Output: Complete pipeline on RHEL 10
```

### Method 8: Amazon Linux 2023
```bash
# Step 1: Install required packages
sudo dnf update -y
sudo dnf install -y curl wget git docker

# Step 2: Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Step 3: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Step 4: Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Step 5: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh && chmod +x */*.sh
./deploy-all.sh

# Expected Output: Complete pipeline on Amazon Linux 2023
```

### Method 9: Windows (Native PowerShell)
```bash
# Step 1: Install Chocolatey (Package Manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Step 2: Install required software
choco install docker-desktop -y
choco install git -y
choco install kubernetes-cli -y

# Step 3: Install Minikube
choco install minikube -y

# Step 4: Start Minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Step 5: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
# Note: Use Git Bash or WSL for shell scripts
bash -c "chmod +x *.sh && chmod +x */*.sh && ./deploy-all.sh"

# Expected Output: Complete pipeline on Windows
```

### Method 10: Windows (WSL2 with Ubuntu)
```bash
# Step 1: Install WSL2 and Ubuntu
wsl --install -d Ubuntu

# Step 2: Open Ubuntu terminal and update
sudo apt update && sudo apt upgrade -y

# Step 3: Install Docker in WSL2
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Step 4: Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Step 5: Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Step 6: Clone and run
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh && chmod +x */*.sh
./deploy-all.sh

# Expected Output: Complete pipeline on Windows WSL2
```

## 🚀 Quick Start (Complete Output Example)

### One-Command Deployment
```bash
# Deploy the complete DevOps pipeline
./deploy-all.sh
```

**Complete Expected Output:**
```
================================
Complete DevOps Pipeline Integration Deployment
================================
[INFO] Prerequisites check passed
[STEP] Creating namespace: argocd
namespace/argocd created
[STEP] Creating namespace: jenkins
namespace/jenkins created
[STEP] Creating namespace: sonarqube
namespace/sonarqube created
[STEP] Creating namespace: security
namespace/security created
[STEP] Creating namespace: monitoring
namespace/monitoring created
[STEP] Creating namespace: velero
namespace/velero created
[SUCCESS] All namespaces created

================================
Deploying ArgoCD (GitOps)
================================
[STEP] Installing ArgoCD
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
deployment.apps/argocd-server created
deployment.apps/argocd-application-controller created
deployment.apps/argocd-repo-server created
service/argocd-server created
[STEP] Waiting for ArgoCD to be ready
deployment.apps/argocd-server condition met
deployment.apps/argocd-application-controller condition met
[SUCCESS] ArgoCD deployed successfully

================================
Deploying Jenkins (CI/CD)
================================
[STEP] Installing Jenkins
deployment.apps/jenkins created
service/jenkins created
persistentvolumeclaim/jenkins-pvc created
[STEP] Waiting for Jenkins to be ready
deployment.apps/jenkins condition met
[SUCCESS] Jenkins deployed successfully

================================
Deploying SonarQube (Code Quality)
================================
[STEP] Installing SonarQube
deployment.apps/sonarqube created
deployment.apps/postgresql created
service/sonarqube created
service/postgresql created
[STEP] Waiting for SonarQube to be ready
deployment.apps/sonarqube condition met
deployment.apps/postgresql condition met
[SUCCESS] SonarQube deployed successfully

================================
Deploying Monitoring Stack
================================
[STEP] Installing Prometheus
deployment.apps/prometheus created
service/prometheus created
[STEP] Installing Grafana
deployment.apps/grafana created
service/grafana created
[STEP] Waiting for monitoring stack to be ready
deployment.apps/prometheus condition met
deployment.apps/grafana condition met
[SUCCESS] Monitoring stack deployed successfully

================================
Deployment Completed Successfully!
================================

🔗 ArgoCD UI:
   URL: https://localhost:8080
   Username: admin
   Password: abc123def456

🔗 Jenkins UI:
   URL: http://localhost:8081
   Username: admin
   Password: xyz789uvw012

🔗 SonarQube UI:
   URL: http://localhost:9000
   Username: admin
   Password: admin

🔗 Prometheus UI:
   URL: http://localhost:9090

🔗 Grafana UI:
   URL: http://localhost:3000
   Username: admin
   Password: admin

🎉 Complete DevOps Pipeline Integration is now deployed!
```

### Check Deployment Status
```bash
# Check if everything is running
./deploy-all.sh status
```

**Expected Output:**
```
================================
Deployment Status
================================
[INFO] 📊 Namespace Status:
   argocd: Active
   jenkins: Active
   sonarqube: Active
   security: Active
   monitoring: Active
   velero: Active

[INFO] 🚀 Application Status:
NAMESPACE         NAME                    READY   STATUS    RESTARTS   AGE
sample-app-prod   sample-web-app-blue    3/3     Running   0          5m
sample-app-staging sample-web-app         2/2     Running   0          3m
sample-app-dev    sample-web-app          2/2     Running   0          2m

[INFO] 📈 Monitoring Status:
NAMESPACE    NAME         READY   UP-TO-DATE   AVAILABLE   AGE
monitoring   prometheus   1/1     1            1           5m
monitoring   grafana      1/1     1            1           5m

[INFO] 🔒 Security Status:
NAMESPACE    NAME         READY   UP-TO-DATE   AVAILABLE   AGE
sonarqube    sonarqube    1/1     1            1           5m
security     trivy-scan   1/1     1            1           2m
```

## 📁 Project Structure

```
├── README.md                 # This file
├── prerequisites/           # Prerequisites and setup
├── argocd/                 # ArgoCD configuration
├── jenkins/                # Jenkins pipeline setup
├── security/               # Security scanning configs
├── applications/           # Application manifests
├── environments/           # Environment-specific configs
├── backup/                 # Backup and DR setup
├── monitoring/             # Monitoring stack
└── docs/                   # Additional documentation
```

## 🎓 Learning Objectives

By completing this project, you will learn:

- ✅ GitOps principles and ArgoCD implementation
- ✅ Complete CI/CD pipeline integration
- ✅ Security scanning in DevOps pipelines
- ✅ Multi-environment deployment strategies
- ✅ Blue-Green deployment implementation
- ✅ Backup and disaster recovery setup
- ✅ Production-ready DevOps practices

## 🔧 Technologies Used

- **Container Orchestration**: Kubernetes
- **GitOps**: ArgoCD
- **CI/CD**: Jenkins
- **Security**: Trivy, SonarQube
- **Monitoring**: Prometheus, Grafana
- **Backup**: Velero
- **Infrastructure**: Terraform, Ansible
- **Containerization**: Docker

## 📚 Step-by-Step Implementation

Follow the detailed implementation steps in the `docs/` directory for comprehensive learning:

- [Step 1: GitOps Workflow with ArgoCD](./docs/step1-argocd-gitops.md)
- [Step 2: Security Scanning Integration](./docs/step2-security-scanning.md)
- [Step 3: Multi-Environment Deployments](./docs/step3-multi-environment.md)
- [Step 4: Blue-Green Deployment Strategy](./docs/step4-blue-green.md)
- [Step 5: Backup and Disaster Recovery](./docs/step5-backup-dr.md)
- [Complete Setup Guide](./docs/complete-setup-guide.md)
- [Architecture Diagrams](./docs/architecture-diagram.md)

## 🎯 Key Features

### ✅ Complete CI/CD Pipeline
- **Jenkins**: Automated build, test, and deployment
- **ArgoCD**: GitOps-based continuous deployment
- **Multi-Environment**: Dev, Staging, and Production environments
- **Blue-Green Deployments**: Zero-downtime deployments

### ✅ Security Integration
- **SonarQube**: Code quality and security analysis
- **Trivy**: Container image vulnerability scanning
- **Security Gates**: Automated security checks in pipeline
- **RBAC**: Role-based access control

### ✅ Monitoring & Observability
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alerting**: Proactive monitoring and notifications
- **Health Checks**: Application and infrastructure monitoring

### ✅ Backup & Disaster Recovery
- **Velero**: Kubernetes backup and restore
- **Automated Schedules**: Regular backup automation
- **Cross-Cluster**: Backup and restore across clusters
- **Disaster Recovery**: Complete disaster recovery procedures

### ✅ Production-Ready Features
- **High Availability**: Multi-replica deployments
- **Auto-Scaling**: Horizontal Pod Autoscaler
- **Resource Management**: CPU and memory limits
- **Security Hardening**: Non-root containers, read-only filesystems

## 🛠️ Simple Usage Examples

### 1. Deploy Your First Application
```bash
# Deploy sample application to development
kubectl apply -k environments/dev/

# Check if it's running
kubectl get pods -n sample-app-dev
```

**Expected Output:**
```
deployment.apps/sample-web-app created
service/sample-web-app-service created
namespace/sample-app-dev created

NAME                              READY   STATUS    RESTARTS   AGE
sample-web-app-7d4b8c9f5-abc12   2/2     Running   0          30s
```

### 2. Test Blue-Green Deployment
```bash
# Deploy new version using blue-green strategy
./blue-green/blue-green-script.sh deploy
```

**Expected Output:**
```
[BLUE-GREEN] Starting Blue-Green deployment...
[INFO] Current active version: blue
[BLUE-GREEN] Deploying new version to: green
deployment.apps/sample-web-app-green created
service/sample-web-app-green-service created
[INFO] New version (green) deployed successfully
[INFO] Successfully switched traffic to green
[SUCCESS] Blue-Green deployment completed successfully!
```

### 3. Create Backup
```bash
# Create backup of your application
./backup/backup-script.sh create my-backup sample-app-dev
```

**Expected Output:**
```
[BACKUP] Creating backup: my-backup
[INFO] Backing up namespace: sample-app-dev
Backup request "my-backup" submitted successfully.
[INFO] Backup my-backup completed successfully
```

### 4. Access Your Tools
```bash
# Get all access URLs and passwords
./deploy-all.sh status
```

**Expected Output:**
```
🔗 ArgoCD UI: https://localhost:8080 (admin/abc123)
🔗 Jenkins UI: http://localhost:8081 (admin/xyz789)
🔗 SonarQube UI: http://localhost:9000 (admin/admin)
🔗 Prometheus UI: http://localhost:9090
🔗 Grafana UI: http://localhost:3000 (admin/admin)
```

## 🚨 Common Issues & Solutions

### Issue 1: ArgoCD Not Starting
```bash
# Check ArgoCD status
kubectl get pods -n argocd

# Expected Output (if working):
# NAME                                READY   STATUS    RESTARTS   AGE
# argocd-server-7d4b8c9f5-abc12      1/1     Running   0          5m
# argocd-application-controller-xyz   1/1     Running   0          5m
```

### Issue 2: Jenkins Build Fails
```bash
# Check Jenkins logs
kubectl logs -n jenkins deployment/jenkins

# Expected Output (if working):
# Jenkins is fully up and running
# Ready to accept connections
```

### Issue 3: Application Not Deploying
```bash
# Check application status
kubectl get pods --all-namespaces

# Expected Output (if working):
# NAMESPACE         NAME                    READY   STATUS    RESTARTS   AGE
# sample-app-dev    sample-web-app-abc12   2/2     Running   0          2m
```

### Issue 4: Can't Access Web UIs
```bash
# Use port-forward to access UIs
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl port-forward svc/jenkins -n jenkins 8081:8080
kubectl port-forward svc/grafana -n monitoring 3000:3000
```


## 🚀 Complete Step-by-Step Guide

### Step 1: Download & Setup (2 minutes)
```bash
# Download the project
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6

# Make scripts executable
chmod +x *.sh
chmod +x */*.sh
```

**Expected Output:**
```
Cloning into 'Complete-DevOps-Pipeline-Integration-project6'...
remote: Enumerating objects: 150, done.
remote: Counting objects: 100% (150/150), done.
remote: Compressing objects: 100% (120/120), done.
remote: Total 150 (delta 30), reused 150 (delta 30)
Receiving objects: 100% (150/150), 2.5 MiB | 5.2 MiB/s, done.
```

### Step 2: Deploy Everything (5 minutes)
```bash
# Deploy complete DevOps pipeline
./deploy-all.sh
```

**Expected Output:** (See complete output above in Quick Start section)

### Step 3: Verify Everything is Working (1 minute)
```bash
# Check deployment status
./deploy-all.sh status
```

**Expected Output:**
```
[INFO] 📊 Namespace Status:
   argocd: Active
   jenkins: Active
   sonarqube: Active
   monitoring: Active

[INFO] 🚀 Application Status:
NAMESPACE         NAME                    READY   STATUS    RESTARTS   AGE
sample-app-prod   sample-web-app-blue    3/3     Running   0          5m
```

### Step 4: Access Your Tools (2 minutes)
```bash
# Open these URLs in your browser:
# ArgoCD: https://localhost:8080 (admin/abc123)
# Jenkins: http://localhost:8081 (admin/xyz789)
# Grafana: http://localhost:3000 (admin/admin)
```

### Step 5: Test Your First Deployment (2 minutes)
```bash
# Deploy sample application
kubectl apply -k environments/dev/

# Check if it's running
kubectl get pods -n sample-app-dev
```

**Expected Output:**
```
deployment.apps/sample-web-app created
service/sample-web-app-service created

NAME                              READY   STATUS    RESTARTS   AGE
sample-web-app-7d4b8c9f5-abc12   2/2     Running   0          30s
```

### Step 6: Test Blue-Green Deployment (2 minutes)
```bash
# Deploy new version
./blue-green/blue-green-script.sh deploy
```

**Expected Output:**
```
[BLUE-GREEN] Starting Blue-Green deployment...
[INFO] Successfully switched traffic to green
[SUCCESS] Blue-Green deployment completed successfully!
```

### Step 7: Create Your First Backup (1 minute)
```bash
# Create backup
./backup/backup-script.sh create my-backup sample-app-dev
```

**Expected Output:**
```
[BACKUP] Creating backup: my-backup
[INFO] Backup my-backup completed successfully
```

**🎉 Congratulations! You now have a complete DevOps pipeline running!**

## 🎯 Which Method Should You Choose?

### For Beginners (Recommended)
**Method 1: One-Command Deployment**
- ✅ Easiest to use
- ✅ No manual configuration needed
- ✅ Complete pipeline in 5-10 minutes
- ✅ Perfect for learning and testing

### For Learning
**Method 2: Step-by-Step Manual Deployment**
- ✅ Complete control over each component
- ✅ Learn how each tool works
- ✅ Understand the deployment process
- ✅ Customize configurations

### For Windows/Mac Users
**Method 3: Docker Desktop**
- ✅ Works on Windows and Mac
- ✅ No Linux setup required
- ✅ GUI interface available
- ✅ Easy to manage

### For Production
**Method 4: Cloud Kubernetes**
- ✅ Production-ready deployment
- ✅ Scalable and reliable
- ✅ Cloud provider integration
- ✅ High availability

### For Local Development
**Method 5: Minikube**
- ✅ Local Kubernetes cluster
- ✅ Good for development
- ✅ Isolated environment
- ✅ Easy to reset

### For Lightweight Testing
**Method 6: Kind**
- ✅ Lightweight Kubernetes
- ✅ Fast startup
- ✅ Good for CI/CD testing
- ✅ Minimal resource usage

### For Enterprise Linux
**Method 7: RHEL 10 / CentOS Stream**
- ✅ Enterprise-grade Linux
- ✅ Red Hat ecosystem
- ✅ Long-term support
- ✅ Production-ready

### For AWS Environments
**Method 8: Amazon Linux 2023**
- ✅ Optimized for AWS
- ✅ Pre-configured packages
- ✅ AWS integration
- ✅ Cloud-optimized

### For Windows Users
**Method 9: Windows Native PowerShell**
- ✅ Native Windows experience
- ✅ PowerShell integration
- ✅ Chocolatey package manager
- ✅ Windows-specific tools

### For Windows with Linux
**Method 10: Windows WSL2**
- ✅ Best of both worlds
- ✅ Linux compatibility
- ✅ Windows integration
- ✅ Docker support


## 🔧 Manual Step-by-Step Deployment (Alternative Method)

If you prefer to deploy each component manually instead of using the automated script, follow these steps:

### Step 1: Create Namespaces
```bash
# Create all required namespaces
kubectl create namespace argocd
kubectl create namespace jenkins
kubectl create namespace sonarqube
kubectl create namespace security
kubectl create namespace monitoring
kubectl create namespace velero

# Verify namespaces
kubectl get namespaces

# Expected Output:
# NAME              STATUS   AGE
# argocd            Active   5s
# jenkins           Active   5s
# sonarqube         Active   5s
# security          Active   5s
# monitoring        Active   5s
# velero            Active   5s
```

### Step 2: Deploy ArgoCD (GitOps)
```bash
# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd

# Configure ArgoCD for external access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Expected Output:
# ArgoCD deployed successfully
# Admin password: abc123def456
```

### Step 3: Deploy Jenkins (CI/CD)
```bash
# Deploy Jenkins
kubectl apply -f jenkins/jenkins-deployment.yaml

# Wait for Jenkins to be ready
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Get Jenkins admin password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# Expected Output:
# Jenkins deployed successfully
# Admin password: xyz789uvw012
```

### Step 4: Deploy SonarQube (Code Quality)
```bash
# Deploy SonarQube
kubectl apply -f security/sonarqube-deployment.yaml

# Wait for SonarQube to be ready
kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube
kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n sonarqube

# Expected Output:
# SonarQube deployed successfully
# Access URL: http://localhost:9000 (admin/admin)
```

### Step 5: Deploy Trivy (Security Scanning)
```bash
# Deploy Trivy scanning jobs
kubectl apply -f security/trivy-scan-job.yaml

# Verify Trivy deployment
kubectl get pods -n security

# Expected Output:
# NAME           READY   STATUS    RESTARTS   AGE
# trivy-scan-1   1/1     Running   0          30s
```

### Step 6: Deploy Monitoring Stack
```bash
# Deploy Prometheus
kubectl apply -f monitoring/prometheus-deployment.yaml

# Deploy Grafana
kubectl apply -f monitoring/grafana-deployment.yaml

# Wait for monitoring stack to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Expected Output:
# Prometheus deployed successfully
# Grafana deployed successfully
# Access URLs: http://localhost:9090 (Prometheus), http://localhost:3000 (Grafana)
```

### Step 7: Deploy Velero (Backup & DR)
```bash
# Deploy Velero
kubectl apply -f backup/velero-install.yaml

# Deploy backup schedules
kubectl apply -f backup/backup-schedule.yaml

# Wait for Velero to be ready
kubectl wait --for=condition=available --timeout=300s deployment/velero -n velero

# Expected Output:
# Velero deployed successfully
# Backup schedules created
```

### Step 8: Deploy Sample Applications
```bash
# Deploy to Development environment
kubectl apply -k environments/dev/

# Deploy to Staging environment
kubectl apply -k environments/staging/

# Deploy to Production environment
kubectl apply -k environments/prod/

# Deploy Blue-Green setup
kubectl apply -f blue-green/blue-deployment.yaml
kubectl apply -f blue-green/green-deployment.yaml

# Verify deployments
kubectl get pods --all-namespaces

# Expected Output:
# NAMESPACE         NAME                    READY   STATUS    RESTARTS   AGE
# sample-app-dev    sample-web-app-abc12   2/2     Running   0          30s
# sample-app-staging sample-web-app-xyz     2/2     Running   0          30s
# sample-app-prod   sample-web-app-blue    3/3     Running   0          30s
```

### Step 9: Deploy ArgoCD Applications
```bash
# Create ArgoCD applications
kubectl apply -f argocd/sample-application.yaml

# Verify ArgoCD applications
kubectl get applications -n argocd

# Expected Output:
# NAME                SYNC STATUS   HEALTH STATUS
# sample-web-app      Synced        Healthy
# devops-pipeline-app Synced        Healthy
```

### Step 10: Access Your Tools
```bash
# Port forward to access UIs
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
kubectl port-forward svc/jenkins -n jenkins 8081:8080 &
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &
kubectl port-forward svc/grafana -n monitoring 3000:3000 &

# Expected Output:
# Forwarding from 127.0.0.1:8080 -> 8080
# Forwarding from 127.0.0.1:8081 -> 8080
# Forwarding from 127.0.0.1:9000 -> 9000
# Forwarding from 127.0.0.1:9090 -> 9090
# Forwarding from 127.0.0.1:3000 -> 3000
```

### Step 11: Verify Everything is Working
```bash
# Check all deployments
kubectl get deployments --all-namespaces

# Check all services
kubectl get services --all-namespaces

# Check all pods
kubectl get pods --all-namespaces

# Expected Output:
# All deployments should show "READY" status
# All services should show "ClusterIP" or "LoadBalancer"
# All pods should show "Running" status
```

### Step 12: Additional Verification Commands
```bash
# Check ArgoCD applications
kubectl get applications -n argocd
argocd app list

# Check Jenkins jobs
kubectl exec -n jenkins deployment/jenkins -- ls /var/jenkins_home/jobs

# Check SonarQube projects
curl -u admin:admin http://localhost:9000/api/projects/search

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Grafana dashboards
curl -u admin:admin http://localhost:3000/api/search

# Check Velero backups
velero backup get
velero schedule get

# Expected Output:
# All commands should return successful responses
# No error messages should appear
```

### Step 13: Test Application Functionality
```bash
# Test sample application
kubectl get pods -n sample-app-dev
kubectl port-forward -n sample-app-dev svc/sample-web-app-service 8080:80 &
curl http://localhost:8080

# Test Blue-Green deployment
./blue-green/blue-green-script.sh status
./blue-green/blue-green-script.sh deploy

# Test backup functionality
./backup/backup-script.sh create test-backup sample-app-dev
./backup/backup-script.sh list

# Expected Output:
# Sample app should return HTML response
# Blue-Green deployment should complete successfully
# Backup should be created and listed
```

### Step 14: Performance and Health Checks
```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster health
kubectl get componentstatuses
kubectl get nodes

# Check storage usage
kubectl get pv
kubectl get pvc --all-namespaces

# Check network policies
kubectl get networkpolicies --all-namespaces

# Expected Output:
# All nodes should be Ready
# All pods should have reasonable resource usage
# Storage should be properly allocated
```

### Step 15: Security Verification
```bash
# Check RBAC
kubectl get clusterroles
kubectl get clusterrolebindings

# Check secrets
kubectl get secrets --all-namespaces

# Check security contexts
kubectl get pods -n sample-app-prod -o yaml | grep securityContext

# Check image security
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort | uniq

# Expected Output:
# RBAC should be properly configured
# Secrets should be encrypted
# Security contexts should be set
# Images should be from trusted sources
```

### Manual Deployment Summary
```bash
# Total time: ~30-45 minutes (including installation)
# Total commands: ~100+ commands
# Total components: 6 major components
# Total applications: 3 environments + Blue-Green setup
# Total verification steps: 15 steps

# Access URLs:
# ArgoCD: https://localhost:8080 (admin/[password])
# Jenkins: http://localhost:8081 (admin/[password])
# SonarQube: http://localhost:9000 (admin/admin)
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)

# Quick Commands Reference:
# Check status: kubectl get pods --all-namespaces
# Check logs: kubectl logs -n [namespace] [pod-name]
# Port forward: kubectl port-forward svc/[service-name] -n [namespace] [local-port]:[remote-port]
# Delete everything: kubectl delete namespace [namespace-name]
```

## 🚀 Quick Commands Reference

### Daily Operations
```bash
# Check everything is running
kubectl get pods --all-namespaces | grep -v Running

# Restart a deployment
kubectl rollout restart deployment/[deployment-name] -n [namespace]

# Scale a deployment
kubectl scale deployment [deployment-name] --replicas=3 -n [namespace]

# Check resource usage
kubectl top pods --all-namespaces

# Get logs from a pod
kubectl logs -f [pod-name] -n [namespace]

# Execute command in pod
kubectl exec -it [pod-name] -n [namespace] -- /bin/bash
```

### Troubleshooting Commands
```bash
# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Describe a pod
kubectl describe pod [pod-name] -n [namespace]

# Check service endpoints
kubectl get endpoints -n [namespace]

# Check ingress
kubectl get ingress --all-namespaces

# Check persistent volumes
kubectl get pv,pvc --all-namespaces

# Check secrets
kubectl get secrets --all-namespaces
```

### Cleanup Commands
```bash
# Delete all resources in namespace
kubectl delete all --all -n [namespace]

# Delete namespace (removes everything)
kubectl delete namespace [namespace]

# Clean up completed jobs
kubectl delete jobs --field-selector status.successful=1 --all-namespaces

# Clean up failed pods
kubectl delete pods --field-selector status.phase=Failed --all-namespaces
```

### Monitoring Commands
```bash
# Watch pods in real-time
kubectl get pods --all-namespaces -w

# Check node resources
kubectl describe nodes

# Check cluster info
kubectl cluster-info

# Check API resources
kubectl api-resources

# Check storage classes
kubectl get storageclass
```

## 🎓 What You Learn

### 1. GitOps (Like Having a Smart Assistant)
- **What it is**: Your code in Git automatically becomes your running application
- **Why it's good**: No manual work, everything is automatic
- **Real example**: Push code to GitHub → Application updates automatically

### 2. CI/CD Pipeline (Like an Assembly Line)
- **What it is**: Automated process that builds, tests, and deploys your code
- **Why it's good**: Fast, reliable, no human mistakes
- **Real example**: Code change → Build → Test → Deploy → Done in 5 minutes

### 3. Security Scanning (Like a Security Guard)
- **What it is**: Automatic checking for security problems in your code
- **Why it's good**: Catches problems before they reach customers
- **Real example**: Bad code → Security scan fails → Deployment blocked

### 4. Blue-Green Deployment (Like Having Two Identical Restaurants)
- **What it is**: Two identical environments, switch between them instantly
- **Why it's good**: Zero downtime, instant rollback if problems
- **Real example**: Update restaurant B while A serves customers → Switch instantly

### 5. Monitoring (Like a Health Monitor)
- **What it is**: Constant watching of your application health
- **Why it's good**: Know about problems before customers do
- **Real example**: Server getting slow → Alert sent → Fixed before customers notice

### 6. Backup & Recovery (Like Insurance)
- **What it is**: Automatic saving of your data and applications
- **Why it's good**: Never lose data, quick recovery from disasters
- **Real example**: Server crashes → Restore from backup → Back online in minutes

## 🏆 Success Stories (What You Can Build)

### E-commerce Website
- **Challenge**: Update online store without losing customers
- **Solution**: Blue-Green deployment + monitoring
- **Result**: 99.9% uptime, customers never notice updates

### Banking Application
- **Challenge**: Secure, reliable financial transactions
- **Solution**: Security scanning + automated testing + monitoring
- **Result**: Zero security breaches, 24/7 availability

### Mobile App Backend
- **Challenge**: Handle millions of users, scale automatically
- **Solution**: Auto-scaling + monitoring + multi-environment
- **Result**: Handles traffic spikes, always available

### Healthcare System
- **Challenge**: Critical system, can't afford downtime
- **Solution**: Blue-Green + backup + monitoring + security
- **Result**: 99.99% uptime, instant recovery from any problem


## 📄 License

This project is provided as-is for educational and demonstration purposes.
