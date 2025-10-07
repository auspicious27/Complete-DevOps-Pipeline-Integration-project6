# Step 2: Security Scanning Integration

## 🎯 Learning Objectives

By the end of this step, you will understand:
- Why security scanning is crucial in DevOps pipelines
- How to integrate Trivy for container image scanning
- How to set up SonarQube for code quality analysis
- How to implement security gates in CI/CD pipelines
- How to automate security scanning in Kubernetes

## 🧠 Theory: Security in DevOps

**DevSecOps** is the practice of integrating security into the DevOps pipeline. Security should be "shifted left" - meaning security checks happen early in the development process, not just at the end.

### Security Scanning Types:

1. **Static Application Security Testing (SAST)**: Analyzes source code for vulnerabilities
2. **Container Image Scanning**: Scans container images for known vulnerabilities
3. **Dependency Scanning**: Checks application dependencies for security issues
4. **Infrastructure as Code Scanning**: Validates infrastructure configurations

### Security Pipeline Flow:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Code Commit   │    │   SonarQube     │    │   Build Image   │
│                 │───▶│   SAST Scan     │───▶│                 │
│   Source Code   │    │   Code Quality  │    │   Docker Build  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Deploy to     │    │   Trivy Scan    │    │   Security      │
│   Kubernetes    │◀───│   Container     │───▶│   Gate Check    │
│   Cluster       │    │   Vulnerabilities│    │   Pass/Fail     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Implementation

### 2.1 SonarQube Setup

SonarQube provides continuous inspection of code quality and security.

```bash
# Deploy SonarQube
kubectl apply -f security/sonarqube-deployment.yaml

# Wait for SonarQube to be ready
kubectl wait --for=condition=available --timeout=300s deployment/sonarqube -n sonarqube

# Port forward to access UI
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
```

**Access SonarQube**: http://localhost:9000
- Username: `admin`
- Password: `admin`

### 2.2 Trivy Container Scanning

Trivy is a comprehensive security scanner for containers and other artifacts.

```bash
# Deploy Trivy scanning job
kubectl apply -f security/trivy-scan-job.yaml

# Run a manual scan
kubectl create job --from=cronjob/trivy-scheduled-scan trivy-manual-scan -n security
```

### 2.3 Jenkins Pipeline Integration

The Jenkins pipeline includes security scanning at multiple stages:

```groovy
stage('Security Scan - Trivy') {
    steps {
        script {
            echo '🔒 Running Trivy security scan...'
            sh '''
                # Install Trivy if not present
                if ! command -v trivy &> /dev/null; then
                    wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                    tar zxvf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz
                    sudo mv trivy /usr/local/bin/
                fi
                
                # Scan for vulnerabilities
                trivy fs --format json --output trivy-report.json .
                
                # Check for critical vulnerabilities
                CRITICAL_VULNS=$(trivy fs --severity CRITICAL --format json . | jq '.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")' | wc -l)
                
                if [ "$CRITICAL_VULNS" -gt 0 ]; then
                    echo "❌ Critical vulnerabilities found: $CRITICAL_VULNS"
                    exit 1
                fi
            '''
        }
    }
}
```

## 🔧 Configuration Files

### SonarQube Configuration

```yaml
# SonarQube Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    spec:
      containers:
      - name: sonarqube
        image: sonarqube:9.9-community
        ports:
        - containerPort: 9000
        env:
        - name: SONAR_JDBC_URL
          value: "jdbc:postgresql://postgresql:5432/sonar"
        - name: SONAR_JDBC_USERNAME
          value: "sonar"
        - name: SONAR_JDBC_PASSWORD
          value: "sonar"
```

### Trivy Scanning Job

```yaml
# Trivy Security Scanning Job
apiVersion: batch/v1
kind: Job
metadata:
  name: trivy-scan-job
  namespace: security
spec:
  template:
    spec:
      containers:
      - name: trivy-scanner
        image: aquasec/trivy:0.45.0
        command:
        - /bin/sh
        - -c
        - |
          echo "🔒 Starting Trivy security scan..."
          trivy fs --format json --output /tmp/trivy-fs-report.json /workspace
          trivy fs --format table /workspace
```

## 🚀 Hands-on Exercise

### Exercise 1: Set up SonarQube
1. Deploy SonarQube using the provided manifests
2. Access the SonarQube UI
3. Create a new project
4. Generate an access token

### Exercise 2: Configure Trivy Scanning
1. Deploy the Trivy scanning job
2. Run a manual scan on your application
3. Review the scan results
4. Configure automated scanning

### Exercise 3: Integrate Security in Jenkins
1. Update Jenkins pipeline with security scanning
2. Configure SonarQube integration
3. Set up security gates
4. Test the pipeline with security checks

## 🔍 Security Best Practices

### Container Security:
- ✅ Use minimal base images (Alpine, Distroless)
- ✅ Run containers as non-root users
- ✅ Use read-only root filesystems
- ✅ Set resource limits and requests
- ✅ Regularly update base images

### Code Security:
- ✅ Implement SAST scanning in CI/CD
- ✅ Use dependency scanning tools
- ✅ Follow secure coding practices
- ✅ Regular security training for developers

### Infrastructure Security:
- ✅ Use network policies
- ✅ Implement RBAC
- ✅ Encrypt secrets
- ✅ Regular security audits

## 🔍 Troubleshooting Tips

### Common Issues:

1. **SonarQube not starting**
   ```bash
   # Check logs
   kubectl logs -n sonarqube deployment/sonarqube
   
   # Check PostgreSQL connection
   kubectl logs -n sonarqube deployment/postgresql
   ```

2. **Trivy scan failing**
   ```bash
   # Check job logs
   kubectl logs -n security job/trivy-scan-job
   
   # Verify image accessibility
   docker pull aquasec/trivy:0.45.0
   ```

3. **Security gates blocking deployment**
   ```bash
   # Check Jenkins pipeline logs
   # Review security scan results
   # Fix identified vulnerabilities
   ```

### Best Practices:

- ✅ Run security scans on every build
- ✅ Fail builds on critical vulnerabilities
- ✅ Keep security tools updated
- ✅ Monitor security metrics
- ✅ Regular security reviews

## ✅ What You Learned

In this step, you learned:

1. **Security Integration**: How to integrate security scanning into DevOps pipelines
2. **SonarQube Setup**: How to deploy and configure SonarQube for code quality analysis
3. **Trivy Configuration**: How to set up container image scanning with Trivy
4. **Security Gates**: How to implement security checks that can block deployments
5. **Automated Scanning**: How to automate security scanning in Kubernetes environments

**Next Step**: [Step 3 - Multi-Environment Deployments](./step3-multi-environment.md)
