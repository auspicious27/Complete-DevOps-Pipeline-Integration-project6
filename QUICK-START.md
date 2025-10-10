# 🚀 Quick Start Guide

## Complete DevOps Pipeline Setup in 2 Minutes

### Prerequisites
- Docker installed and running
- Kubernetes cluster (minikube, kind, or cloud)
- Git installed

### Step 1: Clone and Setup
```bash
git clone https://github.com/auspicious27/Complete-DevOps-Pipeline-Integration-project6.git
cd Complete-DevOps-Pipeline-Integration-project6
chmod +x *.sh && chmod +x */*.sh
```

### Step 2: Deploy Everything
```bash
./deploy-all.sh deploy
```

### Step 3: Test Everything Works
```bash
./test-pipeline.sh all
```

### Step 4: Check Status
```bash
./deploy-all.sh status
```

## Access Your Tools

After deployment, access these URLs:

- **ArgoCD**: https://localhost:8080 (admin/[password])
- **Jenkins**: http://localhost:8081 (admin/[password])
- **SonarQube**: http://localhost:9000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

## Quick Commands

```bash
# Deploy pipeline
./deploy-all.sh deploy

# Check status
./deploy-all.sh status

# Test components
./test-pipeline.sh all

# Blue-green deployment
./blue-green/blue-green-script.sh deploy

# Create backup
./backup/backup-script.sh create my-backup sample-app-dev

# Cleanup everything
./deploy-all.sh cleanup
```

## Supported Operating Systems

- ✅ **Linux**: Ubuntu, Debian, CentOS, RHEL, Amazon Linux
- ✅ **macOS**: Intel Macs and Apple Silicon (M1/M2)
- ✅ **Windows**: PowerShell and WSL2
- ✅ **AWS EC2**: All instance types

## Troubleshooting

If something doesn't work:

1. Check logs: `kubectl logs -n [namespace] [pod-name]`
2. Check status: `./deploy-all.sh status`
3. Test components: `./test-pipeline.sh all`
4. Check events: `kubectl get events --all-namespaces`

## Need Help?

- 📖 **Full Documentation**: README.md
- 🔧 **Setup Guide**: SETUP-README.md
- 🐛 **Issues**: Create GitHub issue
- 💬 **Discussions**: GitHub Discussions

---

**🎉 That's it! Your complete DevOps pipeline is ready!**
