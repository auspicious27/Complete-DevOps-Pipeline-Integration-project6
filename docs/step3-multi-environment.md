# Step 3: Multi-Environment Deployments

## 🎯 Learning Objectives

By the end of this step, you will understand:
- How to manage multiple environments (Dev, Staging, Production)
- How to use Kustomize for environment-specific configurations
- How to implement environment promotion workflows
- How to manage secrets and configurations across environments
- How to implement environment-specific resource management

## 🧠 Theory: Multi-Environment Strategy

**Multi-Environment Deployment** is a critical practice in DevOps that allows you to test and validate changes in isolated environments before promoting to production.

### Environment Hierarchy:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │    Staging      │    │   Production    │
│                 │───▶│                 │───▶│                 │
│   Fast Deploy   │    │   Integration   │    │   Stable        │
│   Quick Tests   │    │   Testing       │    │   High Availability│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Principles:

1. **Environment Parity**: Keep environments as similar as possible
2. **Configuration Management**: Use environment-specific configs
3. **Promotion Workflow**: Systematic promotion from Dev → Staging → Prod
4. **Resource Management**: Appropriate resource allocation per environment
5. **Security Isolation**: Separate secrets and access controls

## 🛠️ Implementation

### 3.1 Environment Structure

Our project uses Kustomize for environment management:

```
environments/
├── dev/
│   ├── kustomization.yaml
│   ├── deployment-patch.yaml
│   └── service-patch.yaml
├── staging/
│   ├── kustomization.yaml
│   ├── deployment-patch.yaml
│   └── service-patch.yaml
└── prod/
    ├── kustomization.yaml
    ├── deployment-patch.yaml
    ├── service-patch.yaml
    ├── hpa.yaml
    └── pdb.yaml
```

### 3.2 Development Environment

```bash
# Deploy to development
kubectl apply -k environments/dev/

# Check deployment
kubectl get pods -n sample-app-dev
kubectl get services -n sample-app-dev
```

**Development Characteristics**:
- Fast deployment cycles
- Lower resource requirements
- Debug logging enabled
- Feature flags active
- Quick rollbacks

### 3.3 Staging Environment

```bash
# Deploy to staging
kubectl apply -k environments/staging/

# Run integration tests
kubectl exec -n sample-app-staging deployment/sample-web-app -- curl -f http://localhost:80
```

**Staging Characteristics**:
- Production-like configuration
- Integration testing
- Performance testing
- Security validation
- User acceptance testing

### 3.4 Production Environment

```bash
# Deploy to production
kubectl apply -k environments/prod/

# Check production deployment
kubectl get pods -n sample-app-prod
kubectl get hpa -n sample-app-prod
```

**Production Characteristics**:
- High availability
- Auto-scaling
- Monitoring and alerting
- Backup and disaster recovery
- Security hardening

## 🔧 Configuration Examples

### Development Environment Configuration

```yaml
# environments/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: sample-app-dev

resources:
- ../../applications/sample-app
- deployment-patch.yaml
- service-patch.yaml

commonLabels:
  environment: development
  tier: dev

patchesStrategicMerge:
- deployment-patch.yaml
- service-patch.yaml

images:
- name: nginx
  newTag: 1.21-alpine

replicas:
- name: sample-web-app
  count: 2

configMapGenerator:
- name: app-config
  literals:
  - ENVIRONMENT=development
  - LOG_LEVEL=debug
  - FEATURE_FLAGS=enabled
  - DATABASE_URL=postgresql://dev-db:5432/sampleapp
```

### Production Environment Configuration

```yaml
# environments/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: sample-app-prod

resources:
- ../../applications/sample-app
- deployment-patch.yaml
- service-patch.yaml
- hpa.yaml
- pdb.yaml

commonLabels:
  environment: production
  tier: prod

patchesStrategicMerge:
- deployment-patch.yaml
- service-patch.yaml

images:
- name: nginx
  newTag: 1.21-alpine

replicas:
- name: sample-web-app
  count: 5

configMapGenerator:
- name: app-config
  literals:
  - ENVIRONMENT=production
  - LOG_LEVEL=warn
  - FEATURE_FLAGS=production
  - DATABASE_URL=postgresql://prod-db:5432/sampleapp
```

### Production Deployment Patch

```yaml
# environments/prod/deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-web-app
  namespace: sample-app-prod
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  template:
    spec:
      containers:
      - name: web-app
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "warn"
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

### Horizontal Pod Autoscaler

```yaml
# environments/prod/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sample-web-app-hpa
  namespace: sample-app-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-web-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 🚀 Hands-on Exercise

### Exercise 1: Deploy to Development
1. Deploy the application to the development environment
2. Verify the deployment is working
3. Check the environment-specific configurations
4. Test the application functionality

### Exercise 2: Promote to Staging
1. Deploy the application to the staging environment
2. Run integration tests
3. Verify staging-specific configurations
4. Test the promotion workflow

### Exercise 3: Deploy to Production
1. Deploy the application to the production environment
2. Verify high availability features
3. Check auto-scaling configuration
4. Monitor the production deployment

## 🔍 Environment Management Best Practices

### Configuration Management:
- ✅ Use Kustomize or Helm for environment-specific configs
- ✅ Keep sensitive data in Kubernetes secrets
- ✅ Use ConfigMaps for non-sensitive configuration
- ✅ Implement proper secret rotation

### Resource Management:
- ✅ Right-size resources for each environment
- ✅ Use resource quotas and limits
- ✅ Implement auto-scaling for production
- ✅ Monitor resource usage

### Deployment Strategy:
- ✅ Use blue-green or canary deployments for production
- ✅ Implement proper rollback procedures
- ✅ Use feature flags for gradual rollouts
- ✅ Monitor deployment health

## 🔍 Troubleshooting Tips

### Common Issues:

1. **Environment-specific configuration not applied**
   ```bash
   # Check Kustomize build
   kubectl kustomize environments/dev/
   
   # Verify applied resources
   kubectl get configmap -n sample-app-dev
   ```

2. **Resource constraints in development**
   ```bash
   # Check resource quotas
   kubectl get resourcequota -n sample-app-dev
   
   # Check resource usage
   kubectl top pods -n sample-app-dev
   ```

3. **Production deployment issues**
   ```bash
   # Check HPA status
   kubectl get hpa -n sample-app-prod
   
   # Check PDB status
   kubectl get pdb -n sample-app-prod
   ```

### Best Practices:

- ✅ Use environment-specific namespaces
- ✅ Implement proper RBAC per environment
- ✅ Use different resource classes per environment
- ✅ Monitor and alert per environment
- ✅ Regular environment cleanup

## ✅ What You Learned

In this step, you learned:

1. **Multi-Environment Strategy**: How to structure and manage multiple environments
2. **Kustomize Configuration**: How to use Kustomize for environment-specific deployments
3. **Environment Promotion**: How to implement systematic promotion workflows
4. **Resource Management**: How to configure appropriate resources per environment
5. **Production Readiness**: How to implement high availability and auto-scaling

**Next Step**: [Step 4 - Blue-Green Deployment Strategy](./step4-blue-green.md)
