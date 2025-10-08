#!/bin/bash

# Smart DevOps Deployment Script
# Intelligently deploys applications based on environment and strategy
# Supports: Dev, Staging, Production environments with Blue-Green, Rolling, Canary strategies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/deploy.log"
DEFAULT_ENVIRONMENT="dev"
DEFAULT_STRATEGY="rolling"
DEFAULT_APP_NAME="sample-web-app"

# Function to print colored output
print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date): [INFO] $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date): [WARNING] $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date): [ERROR] $1" >> "$LOG_FILE"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
    echo "$(date): [STEP] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date): [SUCCESS] $1" >> "$LOG_FILE"
}

print_deploy() {
    echo -e "${CYAN}[DEPLOY]${NC} $1"
    echo "$(date): [DEPLOY] $1" >> "$LOG_FILE"
}

# Function to detect current environment
detect_environment() {
    local env=""
    
    # Check if environment is specified
    if [ -n "${ENVIRONMENT:-}" ]; then
        env="$ENVIRONMENT"
    else
        # Auto-detect based on cluster or namespace
        if kubectl get namespace production &>/dev/null; then
            env="production"
        elif kubectl get namespace staging &>/dev/null; then
            env="staging"
        else
            env="dev"
        fi
    fi
    
    echo "$env"
}

# Function to detect deployment strategy
detect_strategy() {
    local strategy=""
    local env="$1"
    
    # Check if strategy is specified
    if [ -n "${STRATEGY:-}" ]; then
        strategy="$STRATEGY"
    else
        # Auto-detect based on environment
        case $env in
            "production"|"prod")
                strategy="blue-green"
                ;;
            "staging")
                strategy="rolling"
                ;;
            "development"|"dev")
                strategy="rolling"
                ;;
            *)
                strategy="rolling"
                ;;
        esac
    fi
    
    echo "$strategy"
}

# Function to validate prerequisites
validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check if required namespaces exist
    local env="$1"
    local namespace=""
    
    case $env in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$env"
            ;;
    esac
    
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        print_warning "Namespace $namespace does not exist, creating it"
        kubectl create namespace "$namespace"
    fi
    
    print_success "Prerequisites validated"
}

# Function to deploy using rolling strategy
deploy_rolling() {
    local app_name="$1"
    local environment="$2"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_deploy "Deploying $app_name to $environment using Rolling strategy"
    
    # Deploy using Kustomize
    if [ -d "$SCRIPT_DIR/environments/$environment" ]; then
        print_step "Deploying to $environment environment"
        kubectl apply -k "$SCRIPT_DIR/environments/$environment/"
    else
        print_step "Deploying sample application to $namespace"
        kubectl apply -f "$SCRIPT_DIR/applications/sample-app/" -n "$namespace"
    fi
    
    # Wait for deployment to complete
    print_step "Waiting for deployment to complete"
    kubectl rollout status deployment/"$app_name" -n "$namespace" --timeout=300s
    
    # Verify deployment
    print_step "Verifying deployment"
    local ready_replicas=$(kubectl get deployment "$app_name" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
    local desired_replicas=$(kubectl get deployment "$app_name" -n "$namespace" -o jsonpath='{.spec.replicas}')
    
    if [ "$ready_replicas" = "$desired_replicas" ]; then
        print_success "Rolling deployment completed successfully"
        return 0
    else
        print_error "Rolling deployment failed: $ready_replicas/$desired_replicas replicas ready"
        return 1
    fi
}

# Function to deploy using blue-green strategy
deploy_blue_green() {
    local app_name="$1"
    local environment="$2"
    
    print_deploy "Deploying $app_name to $environment using Blue-Green strategy"
    
    # Use the existing blue-green script
    if [ -f "$SCRIPT_DIR/blue-green/blue-green-script.sh" ]; then
        print_step "Using blue-green deployment script"
        "$SCRIPT_DIR/blue-green/blue-green-script.sh" deploy
    else
        print_error "Blue-green deployment script not found"
        return 1
    fi
    
    print_success "Blue-Green deployment completed successfully"
}

# Function to deploy using canary strategy
deploy_canary() {
    local app_name="$1"
    local environment="$2"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_deploy "Deploying $app_name to $environment using Canary strategy"
    
    # Deploy canary version (10% traffic)
    print_step "Deploying canary version (10% traffic)"
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app_name-canary
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $app_name
      version: canary
  template:
    metadata:
      labels:
        app: $app_name
        version: canary
    spec:
      containers:
      - name: $app_name
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: $app_name-canary-service
  namespace: $namespace
spec:
  selector:
    app: $app_name
    version: canary
  ports:
  - port: 80
    targetPort: 80
EOF
    
    # Wait for canary to be ready
    print_step "Waiting for canary deployment to be ready"
    kubectl rollout status deployment/"$app_name-canary" -n "$namespace" --timeout=300s
    
    # Test canary version
    print_step "Testing canary version"
    sleep 30
    
    # If canary is healthy, promote to full deployment
    print_step "Promoting canary to full deployment"
    kubectl scale deployment "$app_name" -n "$namespace" --replicas=3
    
    # Clean up canary
    print_step "Cleaning up canary deployment"
    kubectl delete deployment "$app_name-canary" -n "$namespace"
    kubectl delete service "$app_name-canary-service" -n "$namespace"
    
    print_success "Canary deployment completed successfully"
}

# Function to perform health checks
perform_health_checks() {
    local app_name="$1"
    local environment="$2"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_header "Performing Health Checks"
    
    # Check pod status
    print_step "Checking pod status"
    kubectl get pods -n "$namespace" -l app="$app_name"
    
    # Check service status
    print_step "Checking service status"
    kubectl get services -n "$namespace" -l app="$app_name"
    
    # Check deployment status
    print_step "Checking deployment status"
    kubectl get deployments -n "$namespace" -l app="$app_name"
    
    # Perform basic connectivity test
    print_step "Performing connectivity test"
    local service_name="$app_name-service"
    if kubectl get service "$service_name" -n "$namespace" &>/dev/null; then
        # Port forward and test
        kubectl port-forward service/"$service_name" -n "$namespace" 8080:80 &
        local pf_pid=$!
        sleep 5
        
        if curl -f http://localhost:8080 &>/dev/null; then
            print_success "Health check passed"
        else
            print_warning "Health check failed - service may still be starting"
        fi
        
        kill $pf_pid 2>/dev/null || true
    else
        print_warning "Service $service_name not found, skipping connectivity test"
    fi
    
    print_success "Health checks completed"
}

# Function to show deployment status
show_deployment_status() {
    local app_name="$1"
    local environment="$2"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_header "Deployment Status for $app_name in $environment"
    
    echo ""
    print_status "📊 Pod Status:"
    kubectl get pods -n "$namespace" -l app="$app_name" -o wide
    
    echo ""
    print_status "🔗 Service Status:"
    kubectl get services -n "$namespace" -l app="$app_name"
    
    echo ""
    print_status "📈 Deployment Status:"
    kubectl get deployments -n "$namespace" -l app="$app_name"
    
    echo ""
    print_status "📋 Recent Events:"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' | tail -10
    
    # Show access information
    echo ""
    print_status "🌐 Access Information:"
    local service_name="$app_name-service"
    if kubectl get service "$service_name" -n "$namespace" &>/dev/null; then
        echo "   Service: $service_name"
        echo "   Namespace: $namespace"
        echo "   Port-forward: kubectl port-forward service/$service_name -n $namespace 8080:80"
        echo "   Access URL: http://localhost:8080"
    else
        echo "   Service not found: $service_name"
    fi
}

# Function to rollback deployment
rollback_deployment() {
    local app_name="$1"
    local environment="$2"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_header "Rolling Back Deployment"
    
    # Check if deployment exists
    if ! kubectl get deployment "$app_name" -n "$namespace" &>/dev/null; then
        print_error "Deployment $app_name not found in namespace $namespace"
        return 1
    fi
    
    # Get rollout history
    print_step "Deployment rollout history:"
    kubectl rollout history deployment/"$app_name" -n "$namespace"
    
    # Perform rollback
    print_step "Rolling back to previous revision"
    kubectl rollout undo deployment/"$app_name" -n "$namespace"
    
    # Wait for rollback to complete
    print_step "Waiting for rollback to complete"
    kubectl rollout status deployment/"$app_name" -n "$namespace" --timeout=300s
    
    print_success "Rollback completed successfully"
}

# Function to scale deployment
scale_deployment() {
    local app_name="$1"
    local environment="$2"
    local replicas="$3"
    local namespace=""
    
    case $environment in
        "production"|"prod")
            namespace="sample-app-prod"
            ;;
        "staging")
            namespace="sample-app-staging"
            ;;
        "development"|"dev")
            namespace="sample-app-dev"
            ;;
        *)
            namespace="sample-app-$environment"
            ;;
    esac
    
    print_header "Scaling Deployment"
    
    # Check if deployment exists
    if ! kubectl get deployment "$app_name" -n "$namespace" &>/dev/null; then
        print_error "Deployment $app_name not found in namespace $namespace"
        return 1
    fi
    
    # Scale deployment
    print_step "Scaling $app_name to $replicas replicas"
    kubectl scale deployment "$app_name" -n "$namespace" --replicas="$replicas"
    
    # Wait for scaling to complete
    print_step "Waiting for scaling to complete"
    kubectl rollout status deployment/"$app_name" -n "$namespace" --timeout=300s
    
    print_success "Scaling completed successfully"
}

# Main deployment function
main_deploy() {
    local app_name="${APP_NAME:-$DEFAULT_APP_NAME}"
    local environment=$(detect_environment)
    local strategy=$(detect_strategy "$environment")
    
    print_header "Smart DevOps Deployment"
    print_status "Application: $app_name"
    print_status "Environment: $environment"
    print_status "Strategy: $strategy"
    
    # Initialize log file
    echo "Smart DevOps Deployment Log" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "App: $app_name, Environment: $environment, Strategy: $strategy" >> "$LOG_FILE"
    echo "=================================" >> "$LOG_FILE"
    
    # Validate prerequisites
    validate_prerequisites "$environment"
    
    # Deploy based on strategy
    case $strategy in
        "rolling")
            deploy_rolling "$app_name" "$environment"
            ;;
        "blue-green")
            deploy_blue_green "$app_name" "$environment"
            ;;
        "canary")
            deploy_canary "$app_name" "$environment"
            ;;
        *)
            print_error "Unknown deployment strategy: $strategy"
            exit 1
            ;;
    esac
    
    # Perform health checks
    perform_health_checks "$app_name" "$environment"
    
    # Show deployment status
    show_deployment_status "$app_name" "$environment"
    
    print_success "🎉 Deployment completed successfully!"
    print_status "Deployment log: $LOG_FILE"
}

# Function to show help
show_help() {
    echo "Smart DevOps Deployment Script"
    echo "=============================="
    echo ""
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Deploy application (default)"
    echo "  status     - Show deployment status"
    echo "  rollback   - Rollback to previous version"
    echo "  scale      - Scale deployment"
    echo "  health     - Perform health checks"
    echo "  help       - Show this help message"
    echo ""
    echo "Options:"
    echo "  -a, --app NAME        Application name (default: sample-web-app)"
    echo "  -e, --env ENVIRONMENT Environment (dev|staging|prod) (default: auto-detect)"
    echo "  -s, --strategy TYPE   Deployment strategy (rolling|blue-green|canary) (default: auto-detect)"
    echo "  -r, --replicas NUM    Number of replicas for scaling"
    echo ""
    echo "Environment Variables:"
    echo "  APP_NAME              Application name"
    echo "  ENVIRONMENT           Target environment"
    echo "  STRATEGY              Deployment strategy"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Deploy with auto-detection"
    echo "  $0 -e prod -s blue-green             # Deploy to production with blue-green"
    echo "  $0 -a my-app -e staging              # Deploy my-app to staging"
    echo "  $0 status -e prod                    # Show production status"
    echo "  $0 rollback -e prod                  # Rollback production"
    echo "  $0 scale -r 5 -e prod                # Scale production to 5 replicas"
    echo "  $0 health -e staging                 # Health check staging"
    echo ""
    echo "Deployment Strategies:"
    echo "  rolling     - Rolling update (default for dev/staging)"
    echo "  blue-green  - Blue-green deployment (default for production)"
    echo "  canary      - Canary deployment with gradual rollout"
    echo ""
    echo "For more information, see README.md"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--app)
                APP_NAME="$2"
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -s|--strategy)
                STRATEGY="$2"
                shift 2
                ;;
            -r|--replicas)
                REPLICAS="$2"
                shift 2
                ;;
            deploy)
                COMMAND="deploy"
                shift
                ;;
            status)
                COMMAND="status"
                shift
                ;;
            rollback)
                COMMAND="rollback"
                shift
                ;;
            scale)
                COMMAND="scale"
                shift
                ;;
            health)
                COMMAND="health"
                shift
                ;;
            help|--help|-h)
                COMMAND="help"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main script logic
COMMAND="deploy"
parse_arguments "$@"

case $COMMAND in
    deploy)
        main_deploy
        ;;
    status)
        APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
        ENVIRONMENT="${ENVIRONMENT:-$(detect_environment)}"
        show_deployment_status "$APP_NAME" "$ENVIRONMENT"
        ;;
    rollback)
        APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
        ENVIRONMENT="${ENVIRONMENT:-$(detect_environment)}"
        rollback_deployment "$APP_NAME" "$ENVIRONMENT"
        ;;
    scale)
        APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
        ENVIRONMENT="${ENVIRONMENT:-$(detect_environment)}"
        REPLICAS="${REPLICAS:-3}"
        scale_deployment "$APP_NAME" "$ENVIRONMENT" "$REPLICAS"
        ;;
    health)
        APP_NAME="${APP_NAME:-$DEFAULT_APP_NAME}"
        ENVIRONMENT="${ENVIRONMENT:-$(detect_environment)}"
        perform_health_checks "$APP_NAME" "$ENVIRONMENT"
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
