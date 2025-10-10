# 🚀 Complete DevOps Pipeline - Final Guide

## 📋 Table of Contents
1. [What is DevOps Pipeline?](#what-is-devops-pipeline)
2. [What You Need](#what-you-need)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [How Everything Works](#how-everything-works)
5. [Access Your Tools](#access-your-tools)
6. [Common Commands](#common-commands)
7. [Troubleshooting](#troubleshooting)
8. [What You Can Do Next](#what-you-can-do-next)

---

## 🎯 What is DevOps Pipeline?

### Simple Explanation
DevOps Pipeline ek **automated system** hai jo:
- **Code** ko **automatically build** karta hai
- **Test** karta hai
- **Security check** karta hai
- **Deploy** karta hai
- **Monitor** karta hai

### Real Example
```
Developer Code Push → Jenkins Build → SonarQube Test → ArgoCD Deploy → Monitor
```

### Why Use DevOps?
- ✅ **Fast**: Manual work nahi karna padta
- ✅ **Safe**: Automatic testing aur security
- ✅ **Reliable**: Same process har baar
- ✅ **Scalable**: Multiple environments

---

## 🛠️ What You Need

### System Requirements
- **RAM**: 8GB (16GB recommended)
- **CPU**: 4 cores (8 cores recommended)
- **Storage**: 50GB free space
- **Internet**: Stable connection

### Software Requirements
- **Docker**: Container management
- **Kubernetes**: Cluster management
- **Git**: Code management

### Supported Operating Systems
- ✅ **Linux**: Ubuntu, Debian, CentOS, RHEL, Amazon Linux
- ✅ **macOS**: Intel Macs and Apple Silicon (M1/M2)
- ✅ **Windows**: PowerShell and WSL2
- ✅ **AWS EC2**: All instance types

---

## 🚀 Step-by-Step Setup

### Step 1: Install Docker
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# macOS
brew install --cask docker
open -a Docker

# Windows
# Download Docker Desktop from: https://www.docker.com/products/docker-desktop
```

### Step 2: Install Kubernetes
```bash
# Option A: Minikube (Recommended)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Option B: Kind (Lightweight)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind create cluster --name devops-pipeline
```

### Step 3: Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Step 4: Download DevOps Pipeline
```bash
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh
chmod +x */*.sh
```

### Step 5: Deploy Everything
```bash
# Deploy complete pipeline
./deploy-all.sh deploy

# Test everything works
./test-pipeline.sh all

# Check status
./deploy-all.sh status
```

---

## 🔧 How Everything Works

### 1. ArgoCD (GitOps)
**What it does:**
- Git repository ko watch karta hai
- Changes automatically deploy karta hai
- Rollback kar sakta hai

**How it works:**
```
Git Push → ArgoCD Detects → Kubernetes Deploy → Monitor
```

**Access:**
- URL: https://localhost:8080
- Username: admin
- Password: Check namespace

### 2. Jenkins (CI/CD)
**What it does:**
- Code build karta hai
- Tests run karta hai
- Docker images banata hai
- Deploy karta hai

**How it works:**
```
Code Push → Jenkins Build → Test → Docker Image → Deploy
```

**Access:**
- URL: http://localhost:8081
- Username: admin
- Password: Check namespace

### 3. SonarQube (Code Quality)
**What it does:**
- Code quality check karta hai
- Security vulnerabilities find karta hai
- Code coverage measure karta hai

**How it works:**
```
Code → SonarQube Analysis → Quality Report → Pass/Fail
```

**Access:**
- URL: http://localhost:9000
- Username: admin
- Password: admin

### 4. Trivy (Security Scanning)
**What it does:**
- Container images scan karta hai
- Vulnerabilities find karta hai
- Security reports banata hai

**How it works:**
```
Docker Image → Trivy Scan → Vulnerability Report → Block/Allow
```

### 5. Prometheus (Monitoring)
**What it does:**
- Metrics collect karta hai
- Performance monitor karta hai
- Alerts send karta hai

**How it works:**
```
Applications → Metrics → Prometheus → Storage → Query
```

**Access:**
- URL: http://localhost:9090

### 6. Grafana (Visualization)
**What it does:**
- Metrics display karta hai
- Dashboards banata hai
- Charts aur graphs show karta hai

**How it works:**
```
Prometheus Data → Grafana → Dashboards → Visualization
```

**Access:**
- URL: http://localhost:3000
- Username: admin
- Password: admin

### 7. Velero (Backup)
**What it does:**
- Kubernetes resources backup karta hai
- Disaster recovery provide karta hai
- Scheduled backups banata hai

**How it works:**
```
Kubernetes → Velero → Backup Storage → Restore
```

---

## 🌐 Access Your Tools

### Port Forwarding (Required)
```bash
# Start port forwarding for all services
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
kubectl port-forward svc/jenkins -n jenkins 8081:8080 &
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &
kubectl port-forward svc/grafana -n monitoring 3000:3000 &
```

### Access URLs
- **ArgoCD**: https://localhost:8080 (admin/[password])
- **Jenkins**: http://localhost:8081 (admin/[password])
- **SonarQube**: http://localhost:9000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

### Get Passwords
```bash
# ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Jenkins password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 📝 Common Commands

### Pipeline Management
```bash
# Deploy everything
./deploy-all.sh deploy

# Check status
./deploy-all.sh status

# Test components
./test-pipeline.sh all

# Cleanup
./deploy-all.sh cleanup
```

### Kubernetes Commands
```bash
# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check logs
kubectl logs -n [namespace] [pod-name]

# Restart deployment
kubectl rollout restart deployment/[name] -n [namespace]
```

### Backup Commands
```bash
# Create backup
./backup/backup-script.sh create my-backup sample-app-dev

# List backups
./backup/backup-script.sh list

# Restore backup
./backup/backup-script.sh restore my-backup restore-name
```

### Blue-Green Deployment
```bash
# Deploy new version
./blue-green/blue-green-script.sh deploy

# Check status
./blue-green/blue-green-script.sh status

# Rollback
./blue-green/blue-green-script.sh rollback
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. URLs Not Working
**Problem**: Chrome mein URLs open nahi ho rahe
**Solution**: Port forwarding start karein
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### 2. Pods Not Starting
**Problem**: Pods Running state mein nahi aa rahe
**Solution**: Check logs aur events
```bash
kubectl logs -n [namespace] [pod-name]
kubectl get events --all-namespaces
```

#### 3. Docker Not Running
**Problem**: Docker daemon start nahi ho raha
**Solution**: Docker Desktop start karein
```bash
# macOS
open -a Docker

# Linux
sudo systemctl start docker
```

#### 4. Kubernetes Cluster Not Accessible
**Problem**: kubectl commands fail ho rahe
**Solution**: Cluster restart karein
```bash
minikube start
# ya
kind create cluster --name devops-pipeline
```

#### 5. Out of Memory
**Problem**: System slow ya pods fail
**Solution**: Resource usage check karein
```bash
kubectl top pods --all-namespaces
kubectl top nodes
```

### Debug Commands
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes

# Check all resources
kubectl get all --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods --all-namespaces
kubectl top nodes
```

---

## 🎯 What You Can Do Next

### 1. Deploy Your Own Application
```bash
# Create your application
kubectl create deployment my-app --image=nginx

# Expose service
kubectl expose deployment my-app --port=80 --type=LoadBalancer

# Check status
kubectl get pods,svc
```

### 2. Set Up CI/CD Pipeline
```bash
# Create Jenkins job
# 1. Go to Jenkins UI
# 2. New Item → Pipeline
# 3. Configure pipeline script
# 4. Save and Build
```

### 3. Monitor Your Application
```bash
# Add monitoring annotations
kubectl annotate pod [pod-name] prometheus.io/scrape=true
kubectl annotate pod [pod-name] prometheus.io/port=8080
```

### 4. Set Up Alerts
```bash
# Create alert rules in Prometheus
# Configure notification channels in Grafana
# Set up email/Slack notifications
```

### 5. Backup Your Data
```bash
# Schedule regular backups
./backup/backup-script.sh create daily-backup sample-app-prod

# Test restore
./backup/backup-script.sh restore daily-backup test-restore
```

---

## 📚 Learning Resources

### Documentation
- **README.md**: Main documentation
- **SETUP-README.md**: Detailed setup guide
- **QUICK-START.md**: 2-minute setup

### Useful Links
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

### Commands Reference
```bash
# Pipeline commands
./deploy-all.sh [deploy|status|cleanup|install-tools]
./test-pipeline.sh [all|argocd|jenkins|monitoring|velero]
./backup/backup-script.sh [create|restore|list|schedules]
./blue-green/blue-green-script.sh [deploy|rollback|status]

# Kubernetes commands
kubectl get [pods|svc|deployments|namespaces]
kubectl logs -n [namespace] [pod-name]
kubectl exec -it [pod-name] -n [namespace] -- /bin/bash
kubectl port-forward svc/[service] -n [namespace] [local-port]:[remote-port]
```

---

## 🎉 Congratulations!

You now have a **complete DevOps pipeline** running with:
- ✅ **GitOps** (ArgoCD)
- ✅ **CI/CD** (Jenkins)
- ✅ **Code Quality** (SonarQube)
- ✅ **Security** (Trivy)
- ✅ **Monitoring** (Prometheus + Grafana)
- ✅ **Backup** (Velero)
- ✅ **Blue-Green Deployment**

### Next Steps
1. **Explore** the web UIs
2. **Deploy** your own applications
3. **Monitor** system performance
4. **Learn** more about each tool
5. **Customize** configurations

### Support
- 🐛 **Issues**: Create GitHub issue
- 💬 **Discussions**: GitHub Discussions
- 📖 **Documentation**: README.md files

---

**Happy DevOps! 🚀**

*Made with ❤️ by Md Sayeed Firoz*
