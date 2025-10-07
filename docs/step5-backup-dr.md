# Step 5: Backup and Disaster Recovery

## 🎯 Learning Objectives

By the end of this step, you will understand:
- Why backup and disaster recovery are critical for production systems
- How to implement Velero for Kubernetes backup and restore
- How to create automated backup schedules
- How to implement disaster recovery procedures
- How to test and validate backup and restore processes

## 🧠 Theory: Backup and Disaster Recovery

**Disaster Recovery (DR)** is a set of policies, tools, and procedures to enable the recovery or continuation of vital technology infrastructure and systems following a natural or human-induced disaster.

### Backup Strategy Types:

1. **Full Backup**: Complete backup of all data
2. **Incremental Backup**: Only changes since last backup
3. **Differential Backup**: Changes since last full backup
4. **Continuous Backup**: Real-time backup of changes

### Recovery Objectives:

- **RTO (Recovery Time Objective)**: Maximum acceptable time to restore service
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss

### Backup Architecture:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kubernetes   │    │     Velero      │    │   Cloud Storage │
│   Cluster      │───▶│   Backup Tool   │───▶│   (S3, GCS, etc)│
│                 │    │                 │    │                 │
│   Applications │    │   Schedules     │    │   Backup Files  │
│   Data         │    │   Policies      │    │   Metadata      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Implementation

### 5.1 Velero Setup

Velero is a backup and restore tool for Kubernetes clusters.

```bash
# Deploy Velero
kubectl apply -f backup/velero-install.yaml

# Wait for Velero to be ready
kubectl wait --for=condition=available --timeout=300s deployment/velero -n velero

# Check Velero status
kubectl get pods -n velero
```

### 5.2 Backup Schedules

Create automated backup schedules for different environments:

```bash
# Apply backup schedules
kubectl apply -f backup/backup-schedule.yaml

# Check schedules
kubectl get schedules -n velero
```

### 5.3 Manual Backup Operations

Use the backup script for manual operations:

```bash
# Create a manual backup
./backup/backup-script.sh create prod-backup sample-app-prod

# List all backups
./backup/backup-script.sh list

# Create disaster recovery backup
./backup/backup-script.sh disaster-backup
```

## 🔧 Configuration Files

### Velero Installation

```yaml
# Velero Server Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: velero
  namespace: velero
spec:
  replicas: 1
  selector:
    matchLabels:
      deploy: velero
  template:
    spec:
      serviceAccountName: velero
      containers:
      - name: velero
        image: velero/velero:v1.11.1
        command:
        - /velero
        args:
        - server
        - --features=EnableCSI
        env:
        - name: VELERO_SCRATCH_DIR
          value: /scratch
        - name: VELERO_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

### Backup Storage Location

```yaml
# Backup Storage Location (AWS S3 example)
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: default
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero-backups
    prefix: devops-pipeline
  config:
    region: us-west-2
    s3ForcePathStyle: "false"
  credential:
    name: cloud-credentials
    key: cloud
```

### Backup Schedules

```yaml
# Daily backup schedule for production
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-prod-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  template:
    includedNamespaces:
    - sample-app-prod
    - argocd
    - monitoring
    excludedNamespaces:
    - kube-system
    - kube-public
    - kube-node-lease
    ttl: "720h"  # 30 days
    storageLocation: default
    volumeSnapshotLocations:
    - default
```

## 🚀 Hands-on Exercise

### Exercise 1: Setup Velero
1. Deploy Velero to your Kubernetes cluster
2. Configure backup storage location
3. Verify Velero is working properly
4. Check Velero logs for any issues

### Exercise 2: Create Manual Backup
1. Create a manual backup of your application
2. Verify the backup was created successfully
3. Check backup details and contents
4. Test backup integrity

### Exercise 3: Implement Automated Backups
1. Create backup schedules for different environments
2. Verify schedules are created and running
3. Wait for a scheduled backup to complete
4. Check backup retention policies

### Exercise 4: Test Disaster Recovery
1. Create a disaster recovery backup
2. Simulate a disaster scenario
3. Restore from backup
4. Verify application functionality after restore

## 🔍 Backup Best Practices

### Backup Strategy:
- ✅ Implement 3-2-1 backup rule (3 copies, 2 different media, 1 off-site)
- ✅ Use automated backup schedules
- ✅ Test backup and restore procedures regularly
- ✅ Implement backup retention policies

### Security:
- ✅ Encrypt backups at rest and in transit
- ✅ Use secure backup storage locations
- ✅ Implement proper access controls
- ✅ Regular security audits of backup systems

### Monitoring:
- ✅ Monitor backup success/failure rates
- ✅ Alert on backup failures
- ✅ Regular backup integrity checks
- ✅ Monitor backup storage usage

## 🔍 Troubleshooting Tips

### Common Issues:

1. **Velero not starting**
   ```bash
   # Check Velero logs
   kubectl logs -n velero deployment/velero
   
   # Check Velero configuration
   kubectl get backupstoragelocation -n velero
   ```

2. **Backup failures**
   ```bash
   # Check backup status
   velero backup describe <backup-name>
   
   # Check backup logs
   velero backup logs <backup-name>
   ```

3. **Restore issues**
   ```bash
   # Check restore status
   velero restore describe <restore-name>
   
   # Check restore logs
   velero restore logs <restore-name>
   ```

### Best Practices:

- ✅ Regular backup testing and validation
- ✅ Document backup and restore procedures
- ✅ Implement backup monitoring and alerting
- ✅ Regular disaster recovery drills
- ✅ Keep backup tools updated

## 🔄 Advanced Backup Features

### Cross-Cluster Backup:

```bash
# Backup from one cluster, restore to another
velero backup create cross-cluster-backup --include-namespaces sample-app-prod
velero restore create cross-cluster-restore --from-backup cross-cluster-backup
```

### Selective Backup:

```bash
# Backup specific resources only
velero backup create selective-backup --include-resources deployments,services,configmaps
```

### Backup Hooks:

```yaml
# Pre-backup hook example
hooks:
  resources:
  - name: pre-backup-hook
    includedNamespaces:
    - sample-app-prod
    labelSelector:
      matchLabels:
        app: sample-web-app
    pre:
    - exec:
        container: web-app
        command:
        - /bin/sh
        - -c
        - "echo 'Pre-backup hook: Flushing caches'"
```

## 📊 Backup Monitoring

### Key Metrics to Monitor:

- **Backup Success Rate**: Percentage of successful backups
- **Backup Duration**: Time taken for backup completion
- **Backup Size**: Size of backup files
- **Storage Usage**: Backup storage consumption
- **Restore Time**: Time taken for restore operations

### Alerting Rules:

```yaml
# Example Prometheus alerting rules for backups
groups:
- name: backup.rules
  rules:
  - alert: BackupFailed
    expr: increase(velero_backup_failure_total[1h]) > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Velero backup has failed"
      description: "Backup {{ $labels.backup_name }} has failed"
```

## ✅ What You Learned

In this step, you learned:

1. **Backup and DR Concepts**: Understanding the importance of backup and disaster recovery
2. **Velero Implementation**: How to deploy and configure Velero for Kubernetes backup
3. **Automated Backups**: How to create and manage automated backup schedules
4. **Disaster Recovery**: How to implement disaster recovery procedures
5. **Backup Testing**: How to test and validate backup and restore processes

**Next Step**: [Complete Setup Guide](./complete-setup-guide.md)
