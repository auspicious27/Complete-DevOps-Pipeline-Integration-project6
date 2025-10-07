#!/bin/bash

# Velero Backup and Restore Management Script
# This script provides easy commands for backup and restore operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VELERO_NAMESPACE="velero"
BACKUP_STORAGE_LOCATION="default"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_blue() {
    echo -e "${BLUE}[BACKUP]${NC} $1"
}

# Function to check if Velero is installed
check_velero() {
    if ! kubectl get deployment velero -n $VELERO_NAMESPACE &> /dev/null; then
        print_error "Velero is not installed. Please install Velero first."
        exit 1
    fi
    
    # Check if Velero is ready
    if ! kubectl wait --for=condition=available --timeout=300s deployment/velero -n $VELERO_NAMESPACE; then
        print_error "Velero is not ready. Please check the deployment."
        exit 1
    fi
    
    print_status "Velero is installed and ready"
}

# Function to create a manual backup
create_backup() {
    local backup_name=$1
    local namespace=$2
    
    if [ -z "$backup_name" ]; then
        print_error "Please provide a backup name"
        exit 1
    fi
    
    print_blue "Creating backup: $backup_name"
    
    if [ -n "$namespace" ]; then
        print_status "Backing up namespace: $namespace"
        velero backup create $backup_name --include-namespaces $namespace --wait
    else
        print_status "Creating full cluster backup"
        velero backup create $backup_name --exclude-namespaces kube-system,kube-public,kube-node-lease --wait
    fi
    
    # Check backup status
    local backup_status=$(velero backup describe $backup_name --details | grep "Phase:" | awk '{print $2}')
    
    if [ "$backup_status" = "Completed" ]; then
        print_status "Backup $backup_name completed successfully"
    else
        print_error "Backup $backup_name failed with status: $backup_status"
        exit 1
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_name=$1
    local restore_name=$2
    
    if [ -z "$backup_name" ] || [ -z "$restore_name" ]; then
        print_error "Please provide both backup name and restore name"
        exit 1
    fi
    
    print_blue "Restoring from backup: $backup_name"
    print_status "Restore name: $restore_name"
    
    # Check if backup exists
    if ! velero backup describe $backup_name &> /dev/null; then
        print_error "Backup $backup_name not found"
        exit 1
    fi
    
    # Create restore
    velero restore create $restore_name --from-backup $backup_name --wait
    
    # Check restore status
    local restore_status=$(velero restore describe $restore_name --details | grep "Phase:" | awk '{print $2}')
    
    if [ "$restore_status" = "Completed" ]; then
        print_status "Restore $restore_name completed successfully"
    else
        print_error "Restore $restore_name failed with status: $restore_status"
        exit 1
    fi
}

# Function to list backups
list_backups() {
    print_blue "Listing all backups:"
    velero backup get
}

# Function to list restores
list_restores() {
    print_blue "Listing all restores:"
    velero restore get
}

# Function to delete backup
delete_backup() {
    local backup_name=$1
    
    if [ -z "$backup_name" ]; then
        print_error "Please provide a backup name"
        exit 1
    fi
    
    print_warning "Deleting backup: $backup_name"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        velero backup delete $backup_name --confirm
        print_status "Backup $backup_name deleted"
    else
        print_status "Deletion cancelled"
    fi
}

# Function to show backup details
backup_details() {
    local backup_name=$1
    
    if [ -z "$backup_name" ]; then
        print_error "Please provide a backup name"
        exit 1
    fi
    
    print_blue "Backup details for: $backup_name"
    velero backup describe $backup_name --details
}

# Function to show restore details
restore_details() {
    local restore_name=$1
    
    if [ -z "$restore_name" ]; then
        print_error "Please provide a restore name"
        exit 1
    fi
    
    print_blue "Restore details for: $restore_name"
    velero restore describe $restore_name --details
}

# Function to create disaster recovery backup
create_disaster_recovery_backup() {
    local backup_name="disaster-recovery-$(date +%Y%m%d-%H%M%S)"
    
    print_blue "Creating disaster recovery backup: $backup_name"
    print_warning "This will create a complete cluster backup"
    
    create_backup $backup_name
    print_status "Disaster recovery backup created: $backup_name"
}

# Function to restore from disaster recovery backup
restore_disaster_recovery() {
    local backup_name=$1
    local restore_name="disaster-recovery-restore-$(date +%Y%m%d-%H%M%S)"
    
    if [ -z "$backup_name" ]; then
        print_error "Please provide a backup name"
        exit 1
    fi
    
    print_warning "This will restore the entire cluster from backup: $backup_name"
    print_warning "This operation is destructive and will overwrite existing resources"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_backup $backup_name $restore_name
        print_status "Disaster recovery restore completed: $restore_name"
    else
        print_status "Restore cancelled"
    fi
}

# Function to show backup schedules
show_schedules() {
    print_blue "Backup schedules:"
    velero schedule get
}

# Function to show Velero status
show_status() {
    print_blue "Velero status:"
    velero backup-location get
    echo ""
    velero schedule get
    echo ""
    print_blue "Recent backups:"
    velero backup get --limit 10
}

# Function to cleanup old backups
cleanup_backups() {
    local retention_days=${1:-30}
    
    print_blue "Cleaning up backups older than $retention_days days"
    
    # Get backups older than retention period
    local old_backups=$(velero backup get --output json | jq -r ".items[] | select(.metadata.creationTimestamp < \"$(date -d "$retention_days days ago" -Iseconds)\") | .metadata.name")
    
    if [ -z "$old_backups" ]; then
        print_status "No old backups found"
        return 0
    fi
    
    echo "$old_backups" | while read backup; do
        if [ -n "$backup" ]; then
            print_status "Deleting old backup: $backup"
            velero backup delete $backup --confirm
        fi
    done
    
    print_status "Cleanup completed"
}

# Main script logic
case "${1:-}" in
    create)
        check_velero
        create_backup "${2:-}" "${3:-}"
        ;;
    restore)
        check_velero
        restore_backup "${2:-}" "${3:-}"
        ;;
    list)
        check_velero
        list_backups
        ;;
    list-restores)
        check_velero
        list_restores
        ;;
    delete)
        check_velero
        delete_backup "${2:-}"
        ;;
    details)
        check_velero
        backup_details "${2:-}"
        ;;
    restore-details)
        check_velero
        restore_details "${2:-}"
        ;;
    disaster-backup)
        check_velero
        create_disaster_recovery_backup
        ;;
    disaster-restore)
        check_velero
        restore_disaster_recovery "${2:-}"
        ;;
    schedules)
        check_velero
        show_schedules
        ;;
    status)
        check_velero
        show_status
        ;;
    cleanup)
        check_velero
        cleanup_backups "${2:-}"
        ;;
    *)
        echo "Usage: $0 {create|restore|list|list-restores|delete|details|restore-details|disaster-backup|disaster-restore|schedules|status|cleanup}"
        echo ""
        echo "Commands:"
        echo "  create <name> [namespace]     - Create a backup"
        echo "  restore <backup> <restore>    - Restore from backup"
        echo "  list                          - List all backups"
        echo "  list-restores                 - List all restores"
        echo "  delete <name>                 - Delete a backup"
        echo "  details <name>                - Show backup details"
        echo "  restore-details <name>        - Show restore details"
        echo "  disaster-backup               - Create disaster recovery backup"
        echo "  disaster-restore <backup>     - Restore from disaster recovery backup"
        echo "  schedules                     - Show backup schedules"
        echo "  status                        - Show Velero status"
        echo "  cleanup [days]                - Cleanup old backups (default: 30 days)"
        echo ""
        echo "Examples:"
        echo "  $0 create prod-backup sample-app-prod"
        echo "  $0 restore prod-backup prod-restore"
        echo "  $0 disaster-backup"
        echo "  $0 cleanup 7"
        exit 1
        ;;
esac
