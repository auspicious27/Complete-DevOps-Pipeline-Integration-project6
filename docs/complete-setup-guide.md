# Complete DevOps Pipeline Integration - Setup Guide

## 🎯 Overview

This guide will walk you through setting up a complete, production-ready DevOps pipeline that integrates all major DevOps tools including Docker, Jenkins, Kubernetes, ArgoCD, Security Scanning, Monitoring, and Backup solutions.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   GitHub Repo   │    │   Jenkins CI    │
│                 │───▶│                 │───▶│                 │
│   Git Push      │    │   Source Code   │    │   Build & Test  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Security      │    │   Docker        │    │   ArgoCD        │
│   Scanning      │◀───│   Registry      │───▶│   GitOps        │
│   Trivy/Sonar   │    │   Push Image    │    │   Controller    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │   Monitoring    │    │   Backup & DR   │
│   Cluster       │───▶│   Prometheus    │    │   Velero        │
│   (Dev/Stg/Prod)│    │   Grafana       │    │   Backup        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

### System Requirements
- Kubernetes cluster (v1.20+)
- kubectl configured and working
- Docker installed
- Git installed
- At least 8GB RAM and 4 CPU cores

### Tools to Install
```bash
# Install required tools
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Install Velero CLI
curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
tar -xzf velero-v1.11.1-linux-amd64.tar.gz
sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/
```

## 🚀 Step-by-Step Setup

### Step 1: Clone and Prepare the Project

```bash
# Clone the project
git clone <your-repo-url>
cd "Complete DevOps Pipeline Integration"

# Make scripts executable
chmod +x argocd/setup-script.sh
chmod +x blue-green/blue-green-script.sh
chmod +x backup/backup-script.sh
```

### Step 2: Install ArgoCD (GitOps)

```bash
# Run the ArgoCD setup script
./argocd/setup-script.sh

# Or manually install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Access ArgoCD UI**: https://localhost:8080
- Username: `admin`
- Password: (from the command above)

### Step 3: Install Jenkins (CI/CD)

```bash
# Deploy Jenkins
kubectl apply -f jenkins/jenkins-deployment.yaml

# Wait for Jenkins to be ready
kubectl wait --for=condition=available --timeout=300s deployment/jenkins -n jenkins

# Get Jenkins admin password
kubectl exec -n jenkins deployment/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword

# Port forward to access UI
kubectl port-forward svc/jenkins -n jenkins 8081:8080
```

**Access Jenkins UI**: http://localhost:8081
- Username: `admin`
- Password: (from the command above)

### Step 4: Install Security Scanning Tools

```bash
# Deploy SonarQube
kubectl apply -f security/sonarqube-deployment.yaml

# Wait for SonarQube to be ready
kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube

# Port forward to access UI
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# Deploy Trivy scanning job
kubectl apply -f security/trivy-scan-job.yaml
```

**Access SonarQube UI**: http://localhost:9000
- Username: `admin`
- Password: `admin`

### Step 5: Install Monitoring Stack

```bash
# Deploy Prometheus
kubectl apply -f monitoring/prometheus-deployment.yaml

# Deploy Grafana
kubectl apply -f monitoring/grafana-deployment.yaml

# Wait for services to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Port forward to access UIs
kubectl port-forward svc/prometheus -n monitoring 9090:9090
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

**Access Monitoring UIs**:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

### Step 6: Install Backup Solution (Velero)

```bash
# Deploy Velero
kubectl apply -f backup/velero-install.yaml

# Wait for Velero to be ready
kubectl wait --for=condition=available --timeout=300s deployment/velero -n velero

# Apply backup schedules
kubectl apply -f backup/backup-schedule.yaml
```

### Step 7: Deploy Sample Application

```bash
# Deploy sample application to different environments
kubectl apply -k environments/dev/
kubectl apply -k environments/staging/
kubectl apply -k environments/prod/

# Or use ArgoCD to deploy
kubectl apply -f argocd/sample-application.yaml
```

### Step 8: Configure Blue-Green Deployment

```bash
# Deploy blue-green setup
kubectl apply -f blue-green/blue-deployment.yaml
kubectl apply -f blue-green/green-deployment.yaml

# Test blue-green deployment
./blue-green/blue-green-script.sh status
./blue-green/blue-green-script.sh deploy
```

## 🔧 Configuration

### Jenkins Pipeline Configuration

1. **Create Jenkins Credentials**:
   - Go to Jenkins UI → Manage Jenkins → Manage Credentials
   - Add Docker registry credentials
   - Add SonarQube token
   - Add Kubernetes config

2. **Configure Jenkins Pipeline**:
   - Create a new Pipeline job
   - Point to your Git repository
   - Use the Jenkinsfile from `jenkins/Jenkinsfile`

### ArgoCD Application Configuration

1. **Add Git Repository**:
   - Go to ArgoCD UI → Settings → Repositories
   - Add your Git repository URL
   - Configure authentication if needed

2. **Create Applications**:
   - Go to Applications → New App
   - Configure source (Git repo and path)
   - Configure destination (Kubernetes cluster and namespace)
   - Enable auto-sync for automatic deployments

### Security Scanning Configuration

1. **SonarQube Setup**:
   - Create a new project in SonarQube
   - Generate an access token
   - Configure the token in Jenkins credentials

2. **Trivy Configuration**:
   - Update the image to scan in `security/trivy-scan-job.yaml`
   - Configure the scanning schedule in the CronJob

## 🚀 Usage Examples

### Deploying a New Version

```bash
# 1. Make changes to your application
git add .
git commit -m "Update application to v2.0.0"
git push origin main

# 2. Jenkins will automatically:
#    - Build the application
#    - Run security scans
#    - Push to Docker registry
#    - Update Kubernetes manifests
#    - Trigger ArgoCD sync

# 3. ArgoCD will automatically deploy to the target environment
```

### Blue-Green Deployment

```bash
# Deploy new version using blue-green strategy
./blue-green/blue-green-script.sh deploy

# Check status
./blue-green/blue-green-script.sh status

# Rollback if needed
./blue-green/blue-green-script.sh rollback
```

### Backup and Restore

```bash
# Create a manual backup
./backup/backup-script.sh create prod-backup sample-app-prod

# List backups
./backup/backup-script.sh list

# Restore from backup
./backup/backup-script.sh restore prod-backup prod-restore

# Create disaster recovery backup
./backup/backup-script.sh disaster-backup
```

## 📊 Monitoring and Observability

### Accessing Monitoring Dashboards

1. **Prometheus**: http://localhost:9090
   - Query metrics: `up`, `container_cpu_usage_seconds_total`
   - View targets and service discovery

2. **Grafana**: http://localhost:3000
   - Pre-configured dashboards for Kubernetes
   - Custom dashboards for your applications
   - Set up alerts and notifications

### Key Metrics to Monitor

- **Application Metrics**: Response time, error rate, throughput
- **Infrastructure Metrics**: CPU, memory, disk usage
- **Kubernetes Metrics**: Pod status, node health, resource utilization
- **Security Metrics**: Vulnerability counts, scan results

## 🔒 Security Best Practices

### Implemented Security Measures

1. **Container Security**:
   - Trivy scanning for vulnerabilities
   - Non-root user containers
   - Read-only root filesystems
   - Resource limits and requests

2. **Network Security**:
   - Network policies (configure as needed)
   - TLS encryption for services
   - Secure service-to-service communication

3. **Access Control**:
   - RBAC for Kubernetes resources
   - Service accounts with minimal permissions
   - Git-based access control for ArgoCD

### Security Scanning Workflow

```
Code Commit → SonarQube Analysis → Container Build → Trivy Scan → Deployment
     ↓              ↓                    ↓            ↓           ↓
  Code Quality   Security Issues    Image Build   Vulnerability  Deploy if
   Check          Detection          & Push        Detection      Secure
```

## 🚨 Troubleshooting

### Common Issues and Solutions

1. **ArgoCD Sync Issues**:
   ```bash
   # Check application status
   argocd app get <app-name>
   
   # Force sync
   argocd app sync <app-name> --force
   
   # Check logs
   kubectl logs -n argocd deployment/argocd-application-controller
   ```

2. **Jenkins Build Failures**:
   ```bash
   # Check Jenkins logs
   kubectl logs -n jenkins deployment/jenkins
   
   # Check pipeline logs in Jenkins UI
   # Go to Build → Console Output
   ```

3. **Security Scan Failures**:
   ```bash
   # Check Trivy job logs
   kubectl logs -n security job/trivy-scan-job
   
   # Check SonarQube logs
   kubectl logs -n sonarqube deployment/sonarqube
   ```

4. **Monitoring Issues**:
   ```bash
   # Check Prometheus targets
   # Go to Prometheus UI → Status → Targets
   
   # Check Grafana datasources
   # Go to Grafana UI → Configuration → Data Sources
   ```

### Performance Optimization

1. **Resource Tuning**:
   - Adjust CPU and memory requests/limits
   - Configure Horizontal Pod Autoscaler
   - Optimize container images

2. **Storage Optimization**:
   - Use appropriate storage classes
   - Configure retention policies
   - Monitor disk usage

## 📚 Learning Resources

### Key Concepts to Understand

1. **GitOps**: Declarative infrastructure and application management
2. **CI/CD**: Continuous Integration and Continuous Deployment
3. **Container Security**: Vulnerability scanning and best practices
4. **Kubernetes**: Container orchestration and management
5. **Monitoring**: Observability and alerting
6. **Backup & DR**: Disaster recovery and business continuity

### Recommended Reading

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Velero Documentation](https://velero.io/docs/)

## ✅ What You've Learned

By completing this setup, you now understand:

1. **Complete DevOps Pipeline**: How all tools work together
2. **GitOps Implementation**: ArgoCD for declarative deployments
3. **Security Integration**: Trivy and SonarQube in CI/CD
4. **Multi-Environment Management**: Dev, Staging, Production
5. **Blue-Green Deployments**: Zero-downtime deployment strategy
6. **Monitoring & Observability**: Prometheus and Grafana setup
7. **Backup & Disaster Recovery**: Velero for Kubernetes backups
8. **Production Readiness**: Security, scalability, and reliability

## 🎉 Next Steps

1. **Customize the Pipeline**: Adapt the configurations for your specific needs
2. **Add More Applications**: Deploy additional services using the same pattern
3. **Implement Advanced Features**: Add more sophisticated monitoring and alerting
4. **Scale the Infrastructure**: Add more nodes and optimize resource usage
5. **Enhance Security**: Implement additional security measures and policies

Congratulations! You now have a complete, production-ready DevOps pipeline that demonstrates industry best practices and integrates all major DevOps tools.
