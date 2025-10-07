#!/bin/bash

# Blue-Green Deployment Script
# This script manages blue-green deployments for zero-downtime releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="sample-app-prod"
APP_NAME="sample-web-app"
BLUE_VERSION="blue"
GREEN_VERSION="green"
PROD_SERVICE="sample-web-app-prod"

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
    echo -e "${BLUE}[BLUE-GREEN]${NC} $1"
}

# Function to check if deployment is ready
check_deployment_ready() {
    local deployment_name=$1
    local version=$2
    
    print_status "Checking if $deployment_name ($version) is ready..."
    
    kubectl rollout status deployment/$deployment_name -n $NAMESPACE --timeout=300s
    
    # Additional health check
    local ready_replicas=$(kubectl get deployment $deployment_name -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    local desired_replicas=$(kubectl get deployment $deployment_name -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    
    if [ "$ready_replicas" = "$desired_replicas" ]; then
        print_status "$deployment_name ($version) is ready with $ready_replicas/$desired_replicas replicas"
        return 0
    else
        print_error "$deployment_name ($version) is not ready: $ready_replicas/$desired_replicas replicas"
        return 1
    fi
}

# Function to get current active version
get_current_version() {
    local selector=$(kubectl get service $PROD_SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
    echo $selector
}

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

# Function to deploy new version
deploy_new_version() {
    local current_version=$(get_current_version)
    local new_version=""
    
    if [ "$current_version" = "$BLUE_VERSION" ]; then
        new_version=$GREEN_VERSION
    else
        new_version=$BLUE_VERSION
    fi
    
    print_blue "Current active version: $current_version"
    print_blue "Deploying new version to: $new_version"
    
    # Deploy the new version
    if [ "$new_version" = "$GREEN_VERSION" ]; then
        kubectl apply -f green-deployment.yaml
    else
        kubectl apply -f blue-deployment.yaml
    fi
    
    # Wait for deployment to be ready
    if check_deployment_ready "$APP_NAME-$new_version" "$new_version"; then
        print_status "New version ($new_version) deployed successfully"
        return 0
    else
        print_error "Failed to deploy new version ($new_version)"
        return 1
    fi
}

# Function to test the new version
test_new_version() {
    local current_version=$(get_current_version)
    local test_version=""
    
    if [ "$current_version" = "$BLUE_VERSION" ]; then
        test_version=$GREEN_VERSION
    else
        test_version=$BLUE_VERSION
    fi
    
    print_status "Testing $test_version version..."
    
    # Get the service endpoint for testing
    local test_service="$APP_NAME-$test_version-service"
    local test_url=$(kubectl get service $test_service -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
    
    print_status "Testing endpoint: http://$test_url"
    
    # Simple health check (you can customize this)
    if kubectl run test-pod --rm -i --restart=Never --image=curlimages/curl -- curl -f http://$test_url; then
        print_status "Health check passed for $test_version"
        return 0
    else
        print_error "Health check failed for $test_version"
        return 1
    fi
}

# Function to rollback to previous version
rollback() {
    local current_version=$(get_current_version)
    local rollback_version=""
    
    if [ "$current_version" = "$BLUE_VERSION" ]; then
        rollback_version=$GREEN_VERSION
    else
        rollback_version=$BLUE_VERSION
    fi
    
    print_warning "Rolling back to $rollback_version version..."
    
    if switch_traffic $rollback_version; then
        print_status "Successfully rolled back to $rollback_version"
        return 0
    else
        print_error "Failed to rollback to $rollback_version"
        return 1
    fi
}

# Function to cleanup old version
cleanup_old_version() {
    local current_version=$(get_current_version)
    local old_version=""
    
    if [ "$current_version" = "$BLUE_VERSION" ]; then
        old_version=$GREEN_VERSION
    else
        old_version=$BLUE_VERSION
    fi
    
    print_status "Cleaning up old $old_version version..."
    
    # Scale down the old version
    kubectl scale deployment $APP_NAME-$old_version -n $NAMESPACE --replicas=0
    
    print_status "Old $old_version version scaled down"
}

# Main deployment function
deploy() {
    print_blue "Starting Blue-Green deployment..."
    
    # Step 1: Deploy new version
    if ! deploy_new_version; then
        print_error "Deployment failed"
        exit 1
    fi
    
    # Step 2: Test new version
    if ! test_new_version; then
        print_error "Testing failed, aborting deployment"
        exit 1
    fi
    
    # Step 3: Switch traffic
    local current_version=$(get_current_version)
    local new_version=""
    
    if [ "$current_version" = "$BLUE_VERSION" ]; then
        new_version=$GREEN_VERSION
    else
        new_version=$BLUE_VERSION
    fi
    
    if ! switch_traffic $new_version; then
        print_error "Traffic switch failed"
        exit 1
    fi
    
    # Step 4: Wait and verify
    print_status "Waiting 30 seconds to verify deployment..."
    sleep 30
    
    # Step 5: Cleanup old version (optional)
    read -p "Do you want to cleanup the old version? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_old_version
    fi
    
    print_status "Blue-Green deployment completed successfully!"
}

# Function to show status
status() {
    print_blue "Blue-Green Deployment Status"
    echo "================================"
    
    local current_version=$(get_current_version)
    print_status "Current active version: $current_version"
    
    echo ""
    print_status "Blue version status:"
    kubectl get deployment $APP_NAME-$BLUE_VERSION -n $NAMESPACE -o wide
    
    echo ""
    print_status "Green version status:"
    kubectl get deployment $APP_NAME-$GREEN_VERSION -n $NAMESPACE -o wide
    
    echo ""
    print_status "Production service:"
    kubectl get service $PROD_SERVICE -n $NAMESPACE -o wide
}

# Main script logic
case "${1:-}" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    test)
        test_new_version
        ;;
    switch)
        if [ -z "${2:-}" ]; then
            print_error "Please specify version to switch to (blue or green)"
            exit 1
        fi
        switch_traffic $2
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status|test|switch <version>}"
        echo ""
        echo "Commands:"
        echo "  deploy    - Deploy new version using blue-green strategy"
        echo "  rollback  - Rollback to previous version"
        echo "  status    - Show current deployment status"
        echo "  test      - Test the inactive version"
        echo "  switch    - Switch traffic to specified version (blue/green)"
        exit 1
        ;;
esac
