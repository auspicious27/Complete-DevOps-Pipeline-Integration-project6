# 🚀 Complete DevOps Pipeline Setup Guide

## 📋 Table of Contents
1. [System Requirements](#system-requirements)
2. [OS Detection & Installation](#os-detection--installation)
3. [Quick Setup (2 Minutes)](#quick-setup-2-minutes)
4. [Step-by-Step Detailed Setup](#step-by-step-detailed-setup)
5. [Expected Outputs](#expected-outputs)
6. [Troubleshooting](#troubleshooting)
7. [AWS Instance Setup](#aws-instance-setup)
8. [Verification & Testing](#verification--testing)

---

## 🖥️ System Requirements

### Minimum Requirements
- **RAM**: 8GB (Recommended: 16GB)
- **CPU**: 4 cores (Recommended: 8 cores)
- **Storage**: 50GB free space
- **Internet**: Stable connection
- **OS**: Linux, macOS, Windows, or AWS EC2

### Supported Operating Systems
- ✅ **Linux**: Ubuntu 18.04+, Debian 10+, CentOS 7+, RHEL 8+, Amazon Linux 2023
- ✅ **macOS**: Intel Macs and Apple Silicon (M1/M2)
- ✅ **Windows**: Windows 10/11 with WSL2 or PowerShell
- ✅ **AWS EC2**: All instance types (t2.micro to c5.4xlarge)

---

## 🔍 OS Detection & Installation

### Automatic OS Detection Script
```bash
#!/bin/bash
# OS Detection Script

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
    
    echo "Detected OS: $OS $VERSION"
}

# Detect AWS Instance
detect_aws() {
    if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
        echo "AWS EC2 Instance Detected"
        INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
        echo "Instance Type: $INSTANCE_TYPE"
        return 0
    else
        return 1
    fi
}

detect_os
detect_aws
```

### Expected Output:
```bash
Detected OS: ubuntu 22.04
AWS EC2 Instance Detected
Instance Type: t3.medium
```

---

## ⚡ Quick Setup (2 Minutes)

### One-Command Setup
```bash
# Clone the repository
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6

# Make scripts executable
chmod +x *.sh
chmod +x */*.sh

# Run automatic setup
./final-setup.sh
```

### Expected Output:
```
================================
Complete DevOps Pipeline Integration Deployment
================================
[SUCCESS] Prerequisites check passed
[INFO] Detected OS: ubuntu 22.04
[INFO] AWS EC2 Instance Detected: t3.medium
================================
Creating Namespaces
================================
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
...
[SUCCESS] ArgoCD deployed successfully

================================
Deploying Jenkins (CI/CD)
================================
[STEP] Installing Jenkins
deployment.apps/jenkins created
service/jenkins created
[SUCCESS] Jenkins deployed successfully

================================
Deploying SonarQube (Code Quality)
================================
[STEP] Installing SonarQube
deployment.apps/sonarqube created
service/sonarqube created
[SUCCESS] SonarQube deployed successfully

================================
Deploying Trivy (Security Scanning)
================================
[STEP] Installing Trivy scanning jobs
job.batch/trivy-scan-job created
cronjob.batch/trivy-scheduled-scan created
[SUCCESS] Trivy deployed successfully

================================
Deploying Monitoring Stack
================================
[STEP] Installing Prometheus
deployment.apps/prometheus created
service/prometheus created
[STEP] Installing Grafana
deployment.apps/grafana created
service/grafana created
[SUCCESS] Monitoring stack deployed successfully

================================
Deploying Velero (Backup & DR)
================================
[STEP] Installing Velero CRDs first
customresourcedefinition.apiextensions.k8s.io/backups.velero.io created
...
[SUCCESS] Velero deployed successfully

================================
Deploying Sample Applications
================================
[STEP] Deploying to Development environment
[STEP] Deploying to Staging environment
[STEP] Deploying to Production environment
[STEP] Deploying Blue-Green setup
[SUCCESS] Sample applications deployed successfully

================================
Deployment Completed Successfully!
================================

🔗 ArgoCD UI:
   URL: https://localhost:8080
   Username: admin
   Password: Check ArgoCD namespace for initial admin secret

🔗 Jenkins UI:
   URL: http://localhost:8081
   Username: admin
   Password: Check Jenkins namespace for initial admin password

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

[SUCCESS] 🎉 Complete DevOps Pipeline setup finished successfully!
```

---

## 📚 Step-by-Step Detailed Setup

### Step 1: System Preparation

#### For Ubuntu/Debian:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git docker.io kubectl

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify Docker
docker --version
docker run hello-world
```

**Expected Output:**
```
Docker version 24.0.7, build afdd53b
Hello from Docker!
```

#### For RHEL/CentOS/Amazon Linux:
```bash
# Update system
sudo dnf update -y

# Install required packages
sudo dnf install -y curl wget git docker

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify Docker
docker --version
docker run hello-world
```

**Expected Output:**
```
Docker version 24.0.7, build afdd53b
Hello from Docker!
```

#### For macOS:
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Install kubectl
brew install kubectl

# Start Docker Desktop
open -a Docker
```

**Expected Output:**
```
Docker Desktop is running
kubectl version --client
```

#### For Windows (PowerShell):
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required software
choco install docker-desktop -y
choco install git -y
choco install kubernetes-cli -y

# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

**Expected Output:**
```
Docker Desktop installed successfully
Git installed successfully
kubectl installed successfully
```

### Step 2: Kubernetes Cluster Setup

#### Option A: Minikube (Recommended)
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Verify cluster
minikube status
kubectl cluster-info
```

**Expected Output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured

Kubernetes control plane is running at https://127.0.0.1:32768
```

#### Option B: Kind (Lightweight)
```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name devops-pipeline

# Verify cluster
kind get clusters
kubectl cluster-info
```

**Expected Output:**
```
devops-pipeline
Kubernetes control plane is running at https://127.0.0.1:32768
```

### Step 3: Install Additional Tools

#### Install Helm:
```bash
# Linux/macOS
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm -y

# Verify
helm version
```

**Expected Output:**
```
version.BuildInfo{Version:"v3.12.0", GitCommit:"c9f554d75773799f72ceef38c51210f1842a1dea"}
```

#### Install ArgoCD CLI:
```bash
# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# macOS
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-darwin-amd64
chmod +x /usr/local/bin/argocd

# Windows
choco install argocd -y

# Verify
argocd version --client
```

**Expected Output:**
```
argocd: v2.8.4+unknown
```

#### Install Velero CLI:
```bash
# Linux
curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
tar -xzf velero-v1.11.1-linux-amd64.tar.gz
sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/

# macOS
curl -fsSL -o velero-v1.11.1-darwin-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-darwin-amd64.tar.gz
tar -xzf velero-v1.11.1-darwin-amd64.tar.gz
sudo mv velero-v1.11.1-darwin-amd64/velero /usr/local/bin/

# Windows
choco install velero -y

# Verify
velero version --client
```

**Expected Output:**
```
Client: v1.11.1
```

### Step 4: Deploy DevOps Pipeline

#### Clone Repository:
```bash
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
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

#### Make Scripts Executable:
```bash
chmod +x *.sh
chmod +x */*.sh
```

**Expected Output:**
```
Scripts made executable successfully
```

#### Run Deployment:
```bash
./final-setup.sh
```

**Expected Output:** (See Quick Setup section above)

---

## 🖥️ AWS Instance Setup

### AWS EC2 Specific Instructions

#### Step 1: Launch EC2 Instance
```bash
# Recommended instance types:
# - t3.medium (2 vCPU, 4GB RAM) - Minimum
# - t3.large (2 vCPU, 8GB RAM) - Recommended
# - c5.xlarge (4 vCPU, 8GB RAM) - For production

# Security Group Rules:
# - SSH (22) from your IP
# - HTTP (80) from anywhere
# - HTTPS (443) from anywhere
# - Custom TCP (8080, 8081, 9000, 3000, 9090) from anywhere
```

#### Step 2: Connect to EC2 Instance
```bash
# SSH connection
ssh -i your-key.pem ec2-user@your-ec2-ip

# For Ubuntu instances
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### Step 3: Update System
```bash
# Amazon Linux 2023
sudo dnf update -y

# Ubuntu
sudo apt update && sudo apt upgrade -y
```

#### Step 4: Install Docker
```bash
# Amazon Linux 2023
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Ubuntu
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu
```

#### Step 5: Install kubectl
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

#### Step 6: Install Minikube
```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --memory=8192 --cpus=4 --driver=docker
```

#### Step 7: Deploy Pipeline
```bash
# Clone repository
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6

# Make scripts executable
chmod +x *.sh
chmod +x */*.sh

# Deploy pipeline
./final-setup.sh
```

### AWS EC2 Expected Output:
```
[INFO] Detected OS: amazon 2023
[INFO] AWS EC2 Instance Detected: t3.large
[INFO] Instance ID: i-1234567890abcdef0
[INFO] Region: us-west-2
[INFO] Availability Zone: us-west-2a
================================
Complete DevOps Pipeline Integration Deployment
================================
[SUCCESS] Prerequisites check passed
...
[SUCCESS] 🎉 Complete DevOps Pipeline setup finished successfully!

🔗 Access URLs (Replace localhost with your EC2 public IP):
   ArgoCD: https://your-ec2-ip:8080
   Jenkins: http://your-ec2-ip:8081
   SonarQube: http://your-ec2-ip:9000
   Prometheus: http://your-ec2-ip:9090
   Grafana: http://your-ec2-ip:3000
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Docker Not Starting
```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check Docker logs
sudo journalctl -u docker.service
```

**Expected Output (Fixed):**
```
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
     Active: active (running) since Mon 2024-01-15 10:30:00 UTC; 5min ago
```

#### Issue 2: Minikube Not Starting
```bash
# Check Minikube status
minikube status

# Delete and recreate
minikube delete
minikube start --memory=8192 --cpus=4 --driver=docker

# Check logs
minikube logs
```

**Expected Output (Fixed):**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

#### Issue 3: ArgoCD Not Accessible
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check ArgoCD service
kubectl get svc -n argocd

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Expected Output (Fixed):**
```
NAME                                READY   STATUS    RESTARTS   AGE
argocd-server-7d4b8c9f5-abc12      1/1     Running   0          5m
argocd-application-controller-xyz   1/1     Running   0          5m
```

#### Issue 4: Jenkins Build Fails
```bash
# Check Jenkins logs
kubectl logs -n jenkins deployment/jenkins

# Restart Jenkins
kubectl rollout restart deployment/jenkins -n jenkins

# Check Jenkins status
kubectl get pods -n jenkins
```

**Expected Output (Fixed):**
```
Jenkins is fully up and running
Ready to accept connections
```

#### Issue 5: SonarQube Not Starting
```bash
# Check SonarQube logs
kubectl logs -n sonarqube deployment/sonarqube

# Check PostgreSQL
kubectl logs -n sonarqube deployment/postgresql

# Restart SonarQube
kubectl rollout restart deployment/sonarqube -n sonarqube
```

**Expected Output (Fixed):**
```
SonarQube is up and running
PostgreSQL is ready
```

#### Issue 6: Velero CRD Issues
```bash
# Check Velero CRDs
kubectl get crd | grep velero

# Reinstall Velero
kubectl delete -f backup/velero-install.yaml
kubectl apply -f backup/velero-install.yaml

# Check Velero pods
kubectl get pods -n velero
```

**Expected Output (Fixed):**
```
backups.velero.io                   2024-01-15T10:30:00Z
backupstoragelocations.velero.io    2024-01-15T10:30:00Z
restores.velero.io                  2024-01-15T10:30:00Z
schedules.velero.io                 2024-01-15T10:30:00Z
volumesnapshotlocations.velero.io   2024-01-15T10:30:00Z
```

### Error Messages and Solutions

#### Error: "no matches for kind BackupStorageLocation"
```bash
# Solution: Install Velero CRDs first
kubectl apply -f backup/velero-install.yaml
```

#### Error: "ensure CRDs are installed first"
```bash
# Solution: Wait for CRDs to be established
kubectl wait --for condition=established --timeout=60s crd/backups.velero.io
```

#### Error: "Docker daemon not running"
```bash
# Solution: Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

#### Error: "Minikube start failed"
```bash
# Solution: Check system resources
free -h
df -h
# Increase memory if needed
minikube start --memory=8192 --cpus=4 --driver=docker
```

---

## ✅ Verification & Testing

### Step 1: Check All Pods
```bash
kubectl get pods --all-namespaces
```

**Expected Output:**
```
NAMESPACE         NAME                                READY   STATUS    RESTARTS   AGE
argocd           argocd-server-7d4b8c9f5-abc12      1/1     Running   0          5m
argocd           argocd-application-controller-xyz   1/1     Running   0          5m
jenkins          jenkins-7d4b8c9f5-def45             1/1     Running   0          5m
sonarqube        sonarqube-7d4b8c9f5-ghi78           1/1     Running   0          5m
sonarqube        postgresql-7d4b8c9f5-jkl90           1/1     Running   0          5m
monitoring       prometheus-7d4b8c9f5-mno12           1/1     Running   0          5m
monitoring       grafana-7d4b8c9f5-pqr34             1/1     Running   0          5m
velero           velero-7d4b8c9f5-stu56               1/1     Running   0          5m
sample-app-dev   sample-web-app-7d4b8c9f5-vwx78       2/2     Running   0          3m
sample-app-staging sample-web-app-7d4b8c9f5-yza90     2/2     Running   0          3m
sample-app-prod  sample-web-app-blue-7d4b8c9f5-bcd12  3/3     Running   0          3m
```

### Step 2: Check All Services
```bash
kubectl get svc --all-namespaces
```

**Expected Output:**
```
NAMESPACE         NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
argocd           argocd-server           ClusterIP   10.96.0.100       <none>        443/TCP          5m
jenkins          jenkins                 ClusterIP   10.96.0.101       <none>        8080/TCP         5m
sonarqube        sonarqube              ClusterIP   10.96.0.102       <none>        9000/TCP         5m
monitoring       prometheus             ClusterIP   10.96.0.103       <none>        9090/TCP         5m
monitoring       grafana                ClusterIP   10.96.0.104       <none>        3000/TCP         5m
sample-app-dev   sample-web-app-service ClusterIP   10.96.0.105       <none>        80/TCP           3m
```

### Step 3: Test Port Forwarding
```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
curl -k https://localhost:8080

# Jenkins
kubectl port-forward svc/jenkins -n jenkins 8081:8080 &
curl http://localhost:8081

# SonarQube
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
curl http://localhost:9000

# Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &
curl http://localhost:9090

# Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000 &
curl http://localhost:3000
```

**Expected Output:**
```
ArgoCD: HTTP/2 200
Jenkins: HTTP/1.1 200
SonarQube: HTTP/1.1 200
Prometheus: HTTP/1.1 200
Grafana: HTTP/1.1 200
```

### Step 4: Test Application Deployment
```bash
# Deploy sample application
kubectl apply -k environments/dev/

# Check deployment
kubectl get pods -n sample-app-dev

# Test application
kubectl port-forward -n sample-app-dev svc/sample-web-app-service 8080:80 &
curl http://localhost:8080
```

**Expected Output:**
```
deployment.apps/sample-web-app created
service/sample-web-app-service created

NAME                              READY   STATUS    RESTARTS   AGE
sample-web-app-7d4b8c9f5-abc12   2/2     Running   0          30s

<!DOCTYPE html>
<html>
<head>
    <title>Sample Web App</title>
</head>
<body>
    <h1>Welcome to Sample Web App</h1>
</body>
</html>
```

### Step 5: Test Blue-Green Deployment
```bash
# Deploy blue-green
./blue-green/blue-green-script.sh deploy

# Check status
./blue-green/blue-green-script.sh status
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

[INFO] Blue-Green Status:
   Active Version: green
   Blue Version: Ready
   Green Version: Active
```

### Step 6: Test Backup Functionality
```bash
# Create backup
./backup/backup-script.sh create test-backup sample-app-dev

# List backups
./backup/backup-script.sh list

# Test restore
./backup/backup-script.sh restore test-backup sample-app-dev
```

**Expected Output:**
```
[BACKUP] Creating backup: test-backup
[INFO] Backing up namespace: sample-app-dev
Backup request "test-backup" submitted successfully.
[INFO] Backup test-backup completed successfully

[BACKUP] Listing backups:
NAME          STATUS    CREATED                         EXPIRES
test-backup   Completed  2024-01-15 10:30:00 +0000 UTC   30d

[RESTORE] Restoring backup: test-backup
[INFO] Restoring namespace: sample-app-dev
Restore request "test-backup" submitted successfully.
[INFO] Restore test-backup completed successfully
```

---

## 🎯 Quick Commands Reference

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

---

## 🎉 Success! Your DevOps Pipeline is Ready

### Access Your Tools:
- **ArgoCD**: https://localhost:8080 (admin/[password])
- **Jenkins**: http://localhost:8081 (admin/[password])
- **SonarQube**: http://localhost:9000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

### For AWS EC2:
Replace `localhost` with your EC2 public IP address.

### Next Steps:
1. Configure your Git repositories in ArgoCD
2. Set up Jenkins pipelines for your applications
3. Configure monitoring dashboards in Grafana
4. Test backup and restore procedures with Velero
5. Deploy your own applications using the sample templates

---

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the logs: `kubectl logs -n [namespace] [pod-name]`
3. Check events: `kubectl get events --all-namespaces`
4. Create an issue on GitHub

**Happy DevOps! 🚀**
