# 🚀 DevOps Pipeline Setup Guide

## 🖥️ System Requirements
- **RAM**: 8GB (16GB recommended)
- **CPU**: 4 cores (8 cores recommended)
- **Storage**: 50GB free space
- **OS**: Linux, macOS, Windows, AWS EC2

## 🚀 Quick Setup (2 Minutes)

### Step 1: Install Docker & Kubernetes
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y docker.io
sudo systemctl start docker && sudo usermod -aG docker $USER

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --memory=8192 --cpus=4 --driver=docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Step 2: Deploy Pipeline
```bash
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh && chmod +x */*.sh
./deploy-all.sh deploy
```

### Step 3: Access Tools
```bash
# Port forwarding
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
kubectl port-forward svc/jenkins -n jenkins 8081:8080 &
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
kubectl port-forward svc/prometheus -n monitoring 9090:9090 &
kubectl port-forward svc/grafana -n monitoring 3000:3000 &

# Access URLs
# ArgoCD: https://localhost:8080 (admin/[password])
# Jenkins: http://localhost:8081 (admin/[password])
# SonarQube: http://localhost:9000 (admin/admin)
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)
```

## 🔧 Components Overview

| Component | Purpose | Access URL |
|-----------|---------|------------|
| **ArgoCD** | GitOps Deployment | https://localhost:8080 |
| **Jenkins** | CI/CD Pipeline | http://localhost:8081 |
| **SonarQube** | Code Quality | http://localhost:9000 |
| **Prometheus** | Monitoring | http://localhost:9090 |
| **Grafana** | Dashboards | http://localhost:3000 |
| **Velero** | Backup & DR | CLI Only |

## 📝 Essential Commands

```bash
# Pipeline Management
./deploy-all.sh deploy          # Deploy everything
./deploy-all.sh status          # Check status
./test-pipeline.sh all          # Test components

# Kubernetes
kubectl get pods --all-namespaces
kubectl logs -n [namespace] [pod-name]

# Backup
./backup/backup-script.sh create my-backup sample-app-dev
./backup/backup-script.sh list

# Blue-Green
./blue-green/blue-green-script.sh deploy
./blue-green/blue-green-script.sh rollback
```

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| URLs not working | `kubectl port-forward svc/argocd-server -n argocd 8080:443` |
| Pods not starting | `kubectl logs -n [namespace] [pod-name]` |
| Docker not running | `sudo systemctl start docker` |
| Cluster not accessible | `minikube start` |
| Out of memory | `kubectl top pods --all-namespaces` |

## 🎯 Next Steps

1. **Deploy your app**: `kubectl create deployment my-app --image=nginx`
2. **Set up CI/CD**: Create Jenkins pipeline
3. **Monitor**: Add Prometheus annotations
4. **Backup**: Schedule regular backups
5. **Learn**: Explore web UIs

## 🎉 You're Done!

Complete DevOps pipeline with:
- ✅ GitOps (ArgoCD)
- ✅ CI/CD (Jenkins) 
- ✅ Code Quality (SonarQube)
- ✅ Security (Trivy)
- ✅ Monitoring (Prometheus + Grafana)
- ✅ Backup (Velero)
- ✅ Blue-Green Deployment

**Happy DevOps! 🚀**