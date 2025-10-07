# Step 1: GitOps Workflow with ArgoCD

## 🎯 Learning Objectives

By the end of this step, you will understand:
- What GitOps is and why it's important
- How ArgoCD works as a GitOps controller
- How to set up ArgoCD on Kubernetes
- How to configure automatic deployments from Git repositories
- How to implement GitOps best practices

## 🧠 Theory: What is GitOps?

**GitOps** is a methodology that uses Git as the single source of truth for declarative infrastructure and applications. Here's how it works:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Repository│    │   ArgoCD        │    │   Kubernetes    │
│   (Source of    │───▶│   Controller    │───▶│   Cluster       │
│   Truth)        │    │   (GitOps)      │    │   (Target)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Principles:
1. **Declarative**: Everything is described as code (YAML manifests)
2. **Version Controlled**: All changes tracked in Git
3. **Automated**: Continuous reconciliation between Git and cluster
4. **Observable**: Clear visibility into deployment status

### Benefits:
- ✅ **Consistency**: Same deployment process across all environments
- ✅ **Auditability**: All changes tracked in Git history
- ✅ **Rollback**: Easy to revert to previous versions
- ✅ **Collaboration**: Team can review changes via Pull Requests
- ✅ **Security**: Git-based access control and approval workflows

## 🛠️ Implementation

### 1.1 Install ArgoCD on Kubernetes

First, let's install ArgoCD in our Kubernetes cluster:

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 1.2 Access ArgoCD UI

Get the initial admin password and access the UI:

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD UI at: `https://localhost:8080`
- Username: `admin`
- Password: (from the command above)

### 1.3 Configure ArgoCD CLI

```bash
# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login to ArgoCD
argocd login localhost:8080
```

## 🔧 Configuration Files

### ArgoCD Application Manifest

Create an ArgoCD application that watches your Git repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/your-repo
    targetRevision: HEAD
    path: k8s-manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Sample Application Manifests

Create Kubernetes manifests for your application:

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: nginx:latest
        ports:
        - containerPort: 80
---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

## 🚀 Hands-on Exercise

### Exercise 1: Deploy ArgoCD
1. Run the installation commands above
2. Access the ArgoCD UI
3. Verify ArgoCD is running properly

### Exercise 2: Create Your First GitOps Application
1. Create a GitHub repository with Kubernetes manifests
2. Create an ArgoCD application pointing to your repo
3. Watch ArgoCD automatically deploy your application

### Exercise 3: Test GitOps Workflow
1. Make a change to your Kubernetes manifests in Git
2. Push the changes to your repository
3. Observe ArgoCD automatically sync the changes

## 🔍 Troubleshooting Tips

### Common Issues:

1. **ArgoCD can't access Git repository**
   ```bash
   # Check repository connectivity
   argocd repo list
   argocd repo get <repo-url>
   ```

2. **Application stuck in "Unknown" state**
   ```bash
   # Check application status
   argocd app get <app-name>
   argocd app sync <app-name>
   ```

3. **Sync conflicts**
   ```bash
   # Force sync if needed
   argocd app sync <app-name> --force
   ```

### Best Practices:

- ✅ Use separate Git repositories for different environments
- ✅ Implement proper RBAC for ArgoCD users
- ✅ Use ArgoCD Projects for better organization
- ✅ Enable automated sync only for non-production environments
- ✅ Use health checks and sync waves for complex applications

## ✅ What You Learned

In this step, you learned:

1. **GitOps Fundamentals**: Understanding the GitOps methodology and its benefits
2. **ArgoCD Installation**: How to install and configure ArgoCD on Kubernetes
3. **Application Management**: How to create and manage ArgoCD applications
4. **Automated Deployments**: How ArgoCD automatically syncs changes from Git
5. **Troubleshooting**: Common issues and how to resolve them

**Next Step**: [Step 2 - Security Scanning Integration](./step2-security-scanning.md)
