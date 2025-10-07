# Step 4: Blue-Green Deployment Strategy

## 🎯 Learning Objectives

By the end of this step, you will understand:
- What Blue-Green deployment is and why it's important
- How to implement Blue-Green deployments in Kubernetes
- How to manage traffic switching between environments
- How to implement rollback procedures
- How to automate Blue-Green deployments

## 🧠 Theory: Blue-Green Deployment

**Blue-Green Deployment** is a deployment strategy that reduces downtime and risk by running two identical production environments called Blue and Green. At any time, only one of the environments is live, serving all production traffic.

### Blue-Green Architecture:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │   Blue (Live)   │    │  Green (Standby)│
│                 │───▶│                 │    │                 │
│   Production    │    │   Current Ver   │    │   New Version   │
│   Traffic       │    │   (Active)      │    │   (Testing)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Deployment Process:

1. **Current State**: Blue environment is live, Green is idle
2. **Deploy New Version**: Deploy new version to Green environment
3. **Test Green**: Run tests on Green environment
4. **Switch Traffic**: Route traffic from Blue to Green
5. **Monitor**: Monitor Green environment for issues
6. **Cleanup**: Scale down Blue environment (optional)

### Benefits:

- ✅ **Zero Downtime**: Seamless traffic switching
- ✅ **Quick Rollback**: Instant rollback by switching traffic back
- ✅ **Risk Reduction**: Test new version before going live
- ✅ **Disaster Recovery**: Immediate failover capability

## 🛠️ Implementation

### 4.1 Blue-Green Setup

```bash
# Deploy Blue environment (current production)
kubectl apply -f blue-green/blue-deployment.yaml

# Deploy Green environment (new version)
kubectl apply -f blue-green/green-deployment.yaml

# Check both environments
kubectl get pods -n sample-app-prod -l app=sample-web-app
```

### 4.2 Traffic Management

The production service routes traffic to the active environment:

```yaml
# Production Service - Routes traffic to active environment
apiVersion: v1
kind: Service
metadata:
  name: sample-web-app-prod
  namespace: sample-app-prod
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  selector:
    app: sample-web-app
    version: blue  # Currently pointing to blue
```

### 4.3 Blue-Green Script

Use the provided script to manage Blue-Green deployments:

```bash
# Check current status
./blue-green/blue-green-script.sh status

# Deploy new version
./blue-green/blue-green-script.sh deploy

# Switch traffic manually
./blue-green/blue-green-script.sh switch green

# Rollback if needed
./blue-green/blue-green-script.sh rollback
```

## 🔧 Configuration Files

### Blue Environment (Current Production)

```yaml
# Blue Deployment - Current Production
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-web-app-blue
  namespace: sample-app-prod
  labels:
    app: sample-web-app
    version: blue
    environment: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-web-app
      version: blue
  template:
    metadata:
      labels:
        app: sample-web-app
        version: blue
        environment: production
    spec:
      containers:
      - name: web-app
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
          name: http
        env:
        - name: VERSION
          value: "blue"
```

### Green Environment (New Version)

```yaml
# Green Deployment - New Version
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-web-app-green
  namespace: sample-app-prod
  labels:
    app: sample-web-app
    version: green
    environment: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sample-web-app
      version: green
  template:
    metadata:
      labels:
        app: sample-web-app
        version: green
        environment: production
    spec:
      containers:
      - name: web-app
        image: nginx:1.22-alpine  # New version
        ports:
        - containerPort: 80
          name: http
        env:
        - name: VERSION
          value: "green"
```

### Traffic Switching Logic

```bash
# Function to switch traffic to a specific version
switch_traffic() {
    local target_version=$1
    
    print_blue "Switching traffic to $target_version environment..."
    
    # Update the production service selector
    kubectl patch service $PROD_SERVICE -n $NAMESPACE -p '{"spec":{"selector":{"version":"'$target_version'"}}}'
    
    # Wait for the change to take effect
    sleep 10
    
    # Verify the switch
    local current_version=$(get_current_version)
    if [ "$current_version" = "$target_version" ]; then
        print_status "Successfully switched traffic to $target_version"
        return 0
    else
        print_error "Failed to switch traffic to $target_version"
        return 1
    fi
}
```

## 🚀 Hands-on Exercise

### Exercise 1: Initial Setup
1. Deploy both Blue and Green environments
2. Verify both environments are running
3. Check the current traffic routing
4. Test both environments individually

### Exercise 2: Deploy New Version
1. Update the Green environment with a new version
2. Test the Green environment
3. Switch traffic to Green
4. Verify the new version is serving traffic

### Exercise 3: Rollback Procedure
1. Identify an issue with the new version
2. Rollback by switching traffic back to Blue
3. Verify the rollback was successful
4. Clean up the problematic Green environment

## 🔍 Blue-Green Best Practices

### Deployment Strategy:
- ✅ Always test the new version before switching
- ✅ Implement health checks for both environments
- ✅ Use gradual traffic switching for large deployments
- ✅ Monitor both environments during the switch

### Resource Management:
- ✅ Right-size both environments for production load
- ✅ Use resource quotas to prevent resource exhaustion
- ✅ Implement proper monitoring and alerting
- ✅ Plan for cleanup of the inactive environment

### Risk Management:
- ✅ Implement automated rollback triggers
- ✅ Use feature flags for gradual feature rollouts
- ✅ Test rollback procedures regularly
- ✅ Document deployment and rollback procedures

## 🔍 Troubleshooting Tips

### Common Issues:

1. **Traffic not switching**
   ```bash
   # Check service selector
   kubectl get service sample-web-app-prod -n sample-app-prod -o yaml
   
   # Verify pod labels
   kubectl get pods -n sample-app-prod --show-labels
   ```

2. **New version not ready**
   ```bash
   # Check deployment status
   kubectl rollout status deployment/sample-web-app-green -n sample-app-prod
   
   # Check pod logs
   kubectl logs -n sample-app-prod -l version=green
   ```

3. **Rollback issues**
   ```bash
   # Check Blue environment status
   kubectl get pods -n sample-app-prod -l version=blue
   
   # Verify Blue environment health
   kubectl exec -n sample-app-prod deployment/sample-web-app-blue -- curl -f http://localhost:80
   ```

### Best Practices:

- ✅ Implement comprehensive health checks
- ✅ Use monitoring and alerting for both environments
- ✅ Test deployment procedures in staging first
- ✅ Document all deployment and rollback procedures
- ✅ Regular disaster recovery testing

## 🔄 Advanced Blue-Green Patterns

### Canary Deployment Integration:

```bash
# Gradual traffic switching
./blue-green-script.sh switch --percentage 10 green
./blue-green-script.sh switch --percentage 50 green
./blue-green-script.sh switch --percentage 100 green
```

### Automated Rollback:

```bash
# Automatic rollback on health check failure
./blue-green-script.sh deploy --auto-rollback
```

### Database Migration Support:

```bash
# Deploy with database migration
./blue-green-script.sh deploy --migrate-database
```

## ✅ What You Learned

In this step, you learned:

1. **Blue-Green Deployment**: Understanding the concept and benefits of Blue-Green deployments
2. **Kubernetes Implementation**: How to implement Blue-Green deployments in Kubernetes
3. **Traffic Management**: How to manage traffic switching between environments
4. **Automation**: How to automate Blue-Green deployment procedures
5. **Rollback Procedures**: How to implement quick rollback capabilities

**Next Step**: [Step 5 - Backup and Disaster Recovery](./step5-backup-dr.md)
