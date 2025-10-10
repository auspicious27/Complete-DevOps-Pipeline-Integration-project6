#!/bin/bash

# Velero CRD Fix Script
# This script fixes the Velero CRD issues by applying the CRDs first

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header "Velero CRD Fix Script"
print_status "This script will fix the Velero CRD issues"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_step "Applying Velero CRDs"
kubectl apply -f "$SCRIPT_DIR/backup/velero-install.yaml"

print_step "Waiting for CRDs to be established"
kubectl wait --for condition=established --timeout=60s crd/backups.velero.io || print_warning "Backup CRD wait failed, continuing..."
kubectl wait --for condition=established --timeout=60s crd/backupstoragelocations.velero.io || print_warning "BackupStorageLocation CRD wait failed, continuing..."
kubectl wait --for condition=established --timeout=60s crd/volumesnapshotlocations.velero.io || print_warning "VolumeSnapshotLocation CRD wait failed, continuing..."
kubectl wait --for condition=established --timeout=60s crd/restores.velero.io || print_warning "Restore CRD wait failed, continuing..."
kubectl wait --for condition=established --timeout=60s crd/schedules.velero.io || print_warning "Schedule CRD wait failed, continuing..."

print_step "Verifying CRDs are installed"
kubectl get crd | grep velero.io || print_warning "Some Velero CRDs may not be installed"

print_step "Checking Velero deployment status"
kubectl get pods -n velero || print_warning "Velero namespace may not exist"

print_success "Velero CRD fix completed!"
print_status "You can now run: ./deploy-all.sh velero"
print_status "Or continue with the full deployment: ./deploy-all.sh"
