#!/bin/bash

# DevOps Pipeline Testing Script
# This script tests all components of the DevOps pipeline to ensure they work correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/test.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Function to print colored output
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_step() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Function to test Kubernetes cluster
test_kubernetes() {
    print_step "Testing Kubernetes cluster connectivity..."
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes cluster is accessible"
        log_message "Kubernetes cluster test passed"
        return 0
    else
        print_error "Cannot connect to Kubernetes cluster"
        log_message "Kubernetes cluster test failed"
        return 1
    fi
}

# Function to test namespaces
test_namespaces() {
    print_step "Testing namespaces..."
    
    local namespaces=("argocd" "jenkins" "sonarqube" "security" "monitoring" "velero")
    local failed=0
    
    for namespace in "${namespaces[@]}"; do
        if kubectl get namespace "$namespace" &> /dev/null; then
            print_success "Namespace $namespace exists"
        else
            print_error "Namespace $namespace not found"
            failed=1
        fi
    done
    
    if [ $failed -eq 0 ]; then
        log_message "Namespace test passed"
        return 0
    else
        log_message "Namespace test failed"
        return 1
    fi
}

# Function to test ArgoCD
test_argocd() {
    print_step "Testing ArgoCD..."
    
    local failed=0
    
    # Check if ArgoCD pods are running
    if kubectl get pods -n argocd | grep -q "Running"; then
        print_success "ArgoCD pods are running"
    else
        print_error "ArgoCD pods are not running"
        failed=1
    fi
    
    # Check if ArgoCD service is available
    if kubectl get svc -n argocd argocd-server &> /dev/null; then
        print_success "ArgoCD service is available"
    else
        print_error "ArgoCD service not found"
        failed=1
    fi
    
    # Test ArgoCD API (if accessible)
    if kubectl port-forward svc/argocd-server -n argocd 8080:443 &> /dev/null &; then
        sleep 5
        if curl -k -s https://localhost:8080/api/version &> /dev/null; then
            print_success "ArgoCD API is accessible"
        else
            print_warning "ArgoCD API not accessible (may be normal)"
        fi
        pkill -f "kubectl port-forward.*argocd-server" || true
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "ArgoCD test passed"
        return 0
    else
        log_message "ArgoCD test failed"
        return 1
    fi
}

# Function to test Jenkins
test_jenkins() {
    print_step "Testing Jenkins..."
    
    local failed=0
    
    # Check if Jenkins pods are running
    if kubectl get pods -n jenkins | grep -q "Running"; then
        print_success "Jenkins pods are running"
    else
        print_error "Jenkins pods are not running"
        failed=1
    fi
    
    # Check if Jenkins service is available
    if kubectl get svc -n jenkins jenkins &> /dev/null; then
        print_success "Jenkins service is available"
    else
        print_error "Jenkins service not found"
        failed=1
    fi
    
    # Test Jenkins API (if accessible)
    if kubectl port-forward svc/jenkins -n jenkins 8081:8080 &> /dev/null &; then
        sleep 5
        if curl -s http://localhost:8081/api/json &> /dev/null; then
            print_success "Jenkins API is accessible"
        else
            print_warning "Jenkins API not accessible (may be normal)"
        fi
        pkill -f "kubectl port-forward.*jenkins" || true
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Jenkins test passed"
        return 0
    else
        log_message "Jenkins test failed"
        return 1
    fi
}

# Function to test SonarQube
test_sonarqube() {
    print_step "Testing SonarQube..."
    
    local failed=0
    
    # Check if SonarQube pods are running
    if kubectl get pods -n sonarqube | grep -q "Running"; then
        print_success "SonarQube pods are running"
    else
        print_error "SonarQube pods are not running"
        failed=1
    fi
    
    # Check if PostgreSQL is running
    if kubectl get pods -n sonarqube | grep -q "postgresql.*Running"; then
        print_success "PostgreSQL is running"
    else
        print_error "PostgreSQL is not running"
        failed=1
    fi
    
    # Check if SonarQube service is available
    if kubectl get svc -n sonarqube sonarqube &> /dev/null; then
        print_success "SonarQube service is available"
    else
        print_error "SonarQube service not found"
        failed=1
    fi
    
    # Test SonarQube API (if accessible)
    if kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &> /dev/null &; then
        sleep 5
        if curl -s http://localhost:9000/api/system/status &> /dev/null; then
            print_success "SonarQube API is accessible"
        else
            print_warning "SonarQube API not accessible (may be normal)"
        fi
        pkill -f "kubectl port-forward.*sonarqube" || true
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "SonarQube test passed"
        return 0
    else
        log_message "SonarQube test failed"
        return 1
    fi
}

# Function to test monitoring stack
test_monitoring() {
    print_step "Testing Monitoring Stack..."
    
    local failed=0
    
    # Check if Prometheus is running
    if kubectl get pods -n monitoring | grep -q "prometheus.*Running"; then
        print_success "Prometheus is running"
    else
        print_error "Prometheus is not running"
        failed=1
    fi
    
    # Check if Grafana is running
    if kubectl get pods -n monitoring | grep -q "grafana.*Running"; then
        print_success "Grafana is running"
    else
        print_error "Grafana is not running"
        failed=1
    fi
    
    # Check if Prometheus service is available
    if kubectl get svc -n monitoring prometheus &> /dev/null; then
        print_success "Prometheus service is available"
    else
        print_error "Prometheus service not found"
        failed=1
    fi
    
    # Check if Grafana service is available
    if kubectl get svc -n monitoring grafana &> /dev/null; then
        print_success "Grafana service is available"
    else
        print_error "Grafana service not found"
        failed=1
    fi
    
    # Test Prometheus API (if accessible)
    if kubectl port-forward svc/prometheus -n monitoring 9090:9090 &> /dev/null &; then
        sleep 5
        if curl -s http://localhost:9090/api/v1/query?query=up &> /dev/null; then
            print_success "Prometheus API is accessible"
        else
            print_warning "Prometheus API not accessible (may be normal)"
        fi
        pkill -f "kubectl port-forward.*prometheus" || true
    fi
    
    # Test Grafana API (if accessible)
    if kubectl port-forward svc/grafana -n monitoring 3000:3000 &> /dev/null &; then
        sleep 5
        if curl -s http://localhost:3000/api/health &> /dev/null; then
            print_success "Grafana API is accessible"
        else
            print_warning "Grafana API not accessible (may be normal)"
        fi
        pkill -f "kubectl port-forward.*grafana" || true
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Monitoring test passed"
        return 0
    else
        log_message "Monitoring test failed"
        return 1
    fi
}

# Function to test Velero
test_velero() {
    print_step "Testing Velero..."
    
    local failed=0
    
    # Check if Velero pods are running
    if kubectl get pods -n velero | grep -q "Running"; then
        print_success "Velero pods are running"
    else
        print_error "Velero pods are not running"
        failed=1
    fi
    
    # Check if Velero CRDs are installed
    if kubectl get crd | grep -q "backups.velero.io"; then
        print_success "Velero CRDs are installed"
    else
        print_error "Velero CRDs not found"
        failed=1
    fi
    
    # Check if Velero service is available
    if kubectl get svc -n velero velero &> /dev/null; then
        print_success "Velero service is available"
    else
        print_error "Velero service not found"
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Velero test passed"
        return 0
    else
        log_message "Velero test failed"
        return 1
    fi
}

# Function to test security scanning
test_security() {
    print_step "Testing Security Scanning..."
    
    local failed=0
    
    # Check if Trivy jobs exist
    if kubectl get jobs -n security | grep -q "trivy-scan-job"; then
        print_success "Trivy scan job exists"
    else
        print_error "Trivy scan job not found"
        failed=1
    fi
    
    # Check if Trivy cronjob exists
    if kubectl get cronjobs -n security | grep -q "trivy-scheduled-scan"; then
        print_success "Trivy scheduled scan exists"
    else
        print_error "Trivy scheduled scan not found"
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Security test passed"
        return 0
    else
        log_message "Security test failed"
        return 1
    fi
}

# Function to test sample applications
test_sample_apps() {
    print_step "Testing Sample Applications..."
    
    local failed=0
    
    # Check if sample app namespaces exist
    local sample_namespaces=("sample-app-dev" "sample-app-staging" "sample-app-prod")
    for namespace in "${sample_namespaces[@]}"; do
        if kubectl get namespace "$namespace" &> /dev/null; then
            print_success "Sample app namespace $namespace exists"
        else
            print_error "Sample app namespace $namespace not found"
            failed=1
        fi
    done
    
    # Check if sample app pods are running
    if kubectl get pods --all-namespaces | grep -q "sample-web-app.*Running"; then
        print_success "Sample web app pods are running"
    else
        print_error "Sample web app pods are not running"
        failed=1
    fi
    
    # Check if blue-green deployment exists
    if kubectl get pods -n sample-app-prod | grep -q "sample-web-app-blue.*Running"; then
        print_success "Blue deployment is running"
    else
        print_error "Blue deployment is not running"
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Sample apps test passed"
        return 0
    else
        log_message "Sample apps test failed"
        return 1
    fi
}

# Function to test blue-green deployment
test_blue_green() {
    print_step "Testing Blue-Green Deployment..."
    
    local failed=0
    
    # Check if blue-green script exists and is executable
    if [ -f "$SCRIPT_DIR/blue-green/blue-green-script.sh" ] && [ -x "$SCRIPT_DIR/blue-green/blue-green-script.sh" ]; then
        print_success "Blue-green script is available"
    else
        print_error "Blue-green script not found or not executable"
        failed=1
    fi
    
    # Test blue-green status
    if "$SCRIPT_DIR/blue-green/blue-green-script.sh" status &> /dev/null; then
        print_success "Blue-green status command works"
    else
        print_warning "Blue-green status command failed (may be normal)"
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Blue-green test passed"
        return 0
    else
        log_message "Blue-green test failed"
        return 1
    fi
}

# Function to test backup functionality
test_backup() {
    print_step "Testing Backup Functionality..."
    
    local failed=0
    
    # Check if backup script exists and is executable
    if [ -f "$SCRIPT_DIR/backup/backup-script.sh" ] && [ -x "$SCRIPT_DIR/backup/backup-script.sh" ]; then
        print_success "Backup script is available"
    else
        print_error "Backup script not found or not executable"
        failed=1
    fi
    
    # Test backup list command
    if "$SCRIPT_DIR/backup/backup-script.sh" list &> /dev/null; then
        print_success "Backup list command works"
    else
        print_warning "Backup list command failed (may be normal)"
    fi
    
    if [ $failed -eq 0 ]; then
        log_message "Backup test passed"
        return 0
    else
        log_message "Backup test failed"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    print_header "Running Complete DevOps Pipeline Tests"
    
    # Initialize log file
    echo "DevOps Pipeline Test Log - $TIMESTAMP" > "$LOG_FILE"
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Array of test functions
    local tests=(
        "test_kubernetes"
        "test_namespaces"
        "test_argocd"
        "test_jenkins"
        "test_sonarqube"
        "test_monitoring"
        "test_velero"
        "test_security"
        "test_sample_apps"
        "test_blue_green"
        "test_backup"
    )
    
    # Run each test
    for test in "${tests[@]}"; do
        total_tests=$((total_tests + 1))
        echo ""
        if $test; then
            passed_tests=$((passed_tests + 1))
        else
            failed_tests=$((failed_tests + 1))
        fi
    done
    
    # Print summary
    echo ""
    print_header "Test Summary"
    print_info "Total tests: $total_tests"
    print_success "Passed: $passed_tests"
    if [ $failed_tests -gt 0 ]; then
        print_error "Failed: $failed_tests"
    else
        print_success "Failed: $failed_tests"
    fi
    
    # Calculate success rate
    local success_rate=$((passed_tests * 100 / total_tests))
    print_info "Success rate: $success_rate%"
    
    if [ $failed_tests -eq 0 ]; then
        print_success "🎉 All tests passed! DevOps pipeline is working correctly."
        log_message "All tests passed successfully"
        return 0
    else
        print_warning "⚠️  Some tests failed. Check the logs for details."
        log_message "Some tests failed: $failed_tests/$total_tests"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all           - Run all tests"
    echo "  kubernetes    - Test Kubernetes cluster"
    echo "  namespaces    - Test namespaces"
    echo "  argocd        - Test ArgoCD"
    echo "  jenkins       - Test Jenkins"
    echo "  sonarqube     - Test SonarQube"
    echo "  monitoring    - Test monitoring stack"
    echo "  velero        - Test Velero"
    echo "  security      - Test security scanning"
    echo "  sample-apps   - Test sample applications"
    echo "  blue-green    - Test blue-green deployment"
    echo "  backup        - Test backup functionality"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all"
    echo "  $0 argocd"
    echo "  $0 monitoring"
}

# Main function
main() {
    case "${1:-}" in
        all)
            run_all_tests
            ;;
        kubernetes)
            test_kubernetes
            ;;
        namespaces)
            test_namespaces
            ;;
        argocd)
            test_argocd
            ;;
        jenkins)
            test_jenkins
            ;;
        sonarqube)
            test_sonarqube
            ;;
        monitoring)
            test_monitoring
            ;;
        velero)
            test_velero
            ;;
        security)
            test_security
            ;;
        sample-apps)
            test_sample_apps
            ;;
        blue-green)
            test_blue_green
            ;;
        backup)
            test_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
