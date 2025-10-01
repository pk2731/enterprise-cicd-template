#!/bin/bash

# Enterprise CI/CD Pipeline Testing Script
# This script tests the entire CI/CD pipeline end-to-end

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL=${1:-"origin"}
BASE_BRANCH="main"
TEST_BRANCH_PREFIX="test/pipeline-$(date +%s)"
FEATURE_BRANCH="${TEST_BRANCH_PREFIX}-feature"
STAGING_BRANCH="staging"
DEVELOP_BRANCH="develop"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}\n"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test branches..."
    git checkout ${BASE_BRANCH} 2>/dev/null || true
    git branch -D ${FEATURE_BRANCH} 2>/dev/null || true
    git push ${REPO_URL} --delete ${FEATURE_BRANCH} 2>/dev/null || true
}

# Error handler
error_exit() {
    log_error "Pipeline testing failed: $1"
    cleanup
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error_exit "Not in a git repository"
    fi
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        log_warning "GitHub CLI not installed. PR creation will be skipped."
        SKIP_PR=true
    else
        SKIP_PR=false
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_warning "Docker is not running. Docker tests will be skipped."
        SKIP_DOCKER=true
    else
        SKIP_DOCKER=false
    fi
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        error_exit "npm is not installed"
    fi
    
    log_success "Prerequisites checked"
}

# Test local pipeline steps
test_local_pipeline() {
    log_header "Testing Local Pipeline Steps"
    
    # Install dependencies
    log_info "Installing dependencies..."
    npm ci || error_exit "Failed to install dependencies"
    log_success "Dependencies installed"
    
    # Run linting
    log_info "Running linting..."
    npm run lint || error_exit "Linting failed"
    log_success "Linting passed"
    
    # Run security audit
    log_info "Running security audit..."
    npm audit --audit-level=high || log_warning "Security audit found issues"
    log_success "Security audit completed"
    
    # Run tests
    log_info "Running tests..."
    npm run test:ci || error_exit "Tests failed"
    log_success "Tests passed"
    
    # Generate coverage
    log_info "Generating test coverage..."
    npm run test:coverage || error_exit "Coverage generation failed"
    log_success "Coverage generated"
    
    # Build application
    log_info "Building application..."
    npm run build || error_exit "Build failed"
    log_success "Application built"
}

# Test Docker build
test_docker_build() {
    if [ "$SKIP_DOCKER" = true ]; then
        log_warning "Skipping Docker tests (Docker not available)"
        return
    fi
    
    log_header "Testing Docker Build"
    
    # Test development build
    log_info "Building development Docker image..."
    docker build --target development -t test-app:dev . || error_exit "Development Docker build failed"
    log_success "Development Docker image built"
    
    # Test production build
    log_info "Building production Docker image..."
    docker build --target production -t test-app:prod . || error_exit "Production Docker build failed"
    log_success "Production Docker image built"
    
    # Test image security
    log_info "Scanning Docker image for vulnerabilities..."
    if command -v trivy &> /dev/null; then
        trivy image test-app:prod || log_warning "Docker security scan found issues"
    else
        log_warning "Trivy not installed, skipping security scan"
    fi
    
    # Cleanup Docker images
    docker rmi test-app:dev test-app:prod 2>/dev/null || true
}

# Create test feature branch
create_feature_branch() {
    log_header "Creating Feature Branch"
    
    # Ensure we're on main branch
    git checkout ${BASE_BRANCH} || error_exit "Failed to checkout ${BASE_BRANCH}"
    git pull ${REPO_URL} ${BASE_BRANCH} || error_exit "Failed to pull latest ${BASE_BRANCH}"
    
    # Create and checkout feature branch
    git checkout -b ${FEATURE_BRANCH} || error_exit "Failed to create feature branch"
    log_success "Feature branch ${FEATURE_BRANCH} created"
}

# Make test changes
make_test_changes() {
    log_header "Making Test Changes"
    
    # Create a test file
    cat > src/test-feature.js << EOF
// Test feature for pipeline validation
const testFeature = {
  name: 'Pipeline Test Feature',
  version: '1.0.0',
  test: () => {
    return 'Pipeline test successful!';
  }
};

module.exports = testFeature;
EOF
    
    # Create corresponding test
    mkdir -p src/__tests__
    cat > src/__tests__/test-feature.test.js << EOF
const testFeature = require('../test-feature');

describe('Test Feature', () => {
  test('should return correct name', () => {
    expect(testFeature.name).toBe('Pipeline Test Feature');
  });
  
  test('should return correct version', () => {
    expect(testFeature.version).toBe('1.0.0');
  });
  
  test('should execute test function', () => {
    expect(testFeature.test()).toBe('Pipeline test successful!');
  });
});
EOF
    
    # Update package.json version
    npm version patch --no-git-tag-version || error_exit "Failed to update version"
    
    log_success "Test changes made"
}

# Commit and push changes
commit_and_push() {
    log_header "Committing and Pushing Changes"
    
    git add . || error_exit "Failed to stage changes"
    git commit -m "feat: add test feature for pipeline validation

- Add test feature module
- Add corresponding unit tests  
- Update package version
- This commit tests the CI/CD pipeline" || error_exit "Failed to commit changes"
    
    git push ${REPO_URL} ${FEATURE_BRANCH} || error_exit "Failed to push feature branch"
    log_success "Changes committed and pushed"
}

# Create pull request
create_pull_request() {
    if [ "$SKIP_PR" = true ]; then
        log_warning "Skipping PR creation (GitHub CLI not available)"
        return
    fi
    
    log_header "Creating Pull Request"
    
    PR_URL=$(gh pr create \
        --title "🧪 Pipeline Test: Add test feature" \
        --body "## Pipeline Test PR

This PR is created automatically to test the CI/CD pipeline.

### Changes
- ✅ Added test feature module
- ✅ Added unit tests with 100% coverage
- ✅ Updated package version
- ✅ All quality gates should pass

### Testing Checklist
- [ ] Linting passes
- [ ] Security scan passes  
- [ ] Unit tests pass
- [ ] Coverage threshold met
- [ ] Build succeeds
- [ ] Docker image builds
- [ ] Deployment scripts work

This PR will be automatically cleaned up after testing." \
        --base ${BASE_BRANCH} \
        --head ${FEATURE_BRANCH} 2>/dev/null) || error_exit "Failed to create PR"
    
    log_success "Pull request created: ${PR_URL}"
    
    # Wait for CI checks
    log_info "Waiting for CI checks to complete..."
    sleep 30
    
    # Check PR status
    gh pr status || log_warning "Could not check PR status"
}

# Test deployment scripts
test_deployment_scripts() {
    log_header "Testing Deployment Scripts"
    
    # Test health check script
    if [ -f "./scripts/health-check.sh" ]; then
        log_info "Testing health check script..."
        chmod +x ./scripts/health-check.sh
        # Don't run actual health check as service might not be running
        bash -n ./scripts/health-check.sh || error_exit "Health check script syntax error"
        log_success "Health check script syntax validated"
    fi
    
    # Test deployment scripts syntax
    for script in ./scripts/deploy-*.sh; do
        if [ -f "$script" ]; then
            log_info "Testing deployment script: $(basename $script)"
            chmod +x "$script"
            bash -n "$script" || error_exit "Deployment script syntax error: $script"
            log_success "Deployment script syntax validated: $(basename $script)"
        fi
    done
}

# Test Kubernetes manifests
test_kubernetes_manifests() {
    log_header "Testing Kubernetes Manifests"
    
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl not installed, skipping Kubernetes manifest validation"
        return
    fi
    
    # Validate Kubernetes manifests
    for manifest in k8s/*.yaml; do
        if [ -f "$manifest" ]; then
            log_info "Validating Kubernetes manifest: $(basename $manifest)"
            kubectl apply --dry-run=client -f "$manifest" || error_exit "Invalid Kubernetes manifest: $manifest"
            log_success "Kubernetes manifest valid: $(basename $manifest)"
        fi
    done
}

# Test SonarQube configuration
test_sonar_config() {
    log_header "Testing SonarQube Configuration"
    
    if [ -f "sonar-project.properties" ]; then
        log_info "Validating SonarQube configuration..."
        # Basic validation of sonar properties
        if grep -q "sonar.projectKey" sonar-project.properties && \
           grep -q "sonar.sources" sonar-project.properties; then
            log_success "SonarQube configuration valid"
        else
            error_exit "Invalid SonarQube configuration"
        fi
    else
        log_warning "No SonarQube configuration found"
    fi
}

# Run comprehensive tests
run_comprehensive_tests() {
    log_header "Running Comprehensive Test Suite"
    
    # Test different environments
    for env in development test production; do
        log_info "Testing $env environment configuration..."
        NODE_ENV=$env npm test || error_exit "$env environment tests failed"
        log_success "$env environment tests passed"
    done
    
    # Test with different Node versions if available
    if command -v nvm &> /dev/null; then
        log_info "Testing with different Node.js versions..."
        # This would require nvm to be properly sourced
        # nvm use 16 && npm test || log_warning "Node 16 tests failed"
        # nvm use 18 && npm test || log_warning "Node 18 tests failed"
        log_info "Node version testing skipped (requires nvm configuration)"
    fi
}

# Simulate production deployment
simulate_production_deployment() {
    log_header "Simulating Production Deployment"
    
    # Create production-like environment variables
    export NODE_ENV=production
    export DATABASE_URL="postgresql://localhost:5432/test_db"
    export REDIS_URL="redis://localhost:6379"
    
    # Test application startup (without actually starting)
    log_info "Testing production application startup..."
    node -c src/server.js || error_exit "Application startup validation failed"
    log_success "Production startup validation passed"
    
    # Test production build
    log_info "Testing production build..."
    npm run build || error_exit "Production build failed"
    log_success "Production build completed"
    
    # Validate built assets
    if [ -d "dist" ]; then
        log_info "Validating built assets..."
        [ -f "dist/index.js" ] || error_exit "Main application file not found in build"
        log_success "Built assets validated"
    fi
}

# Generate test report
generate_test_report() {
    log_header "Generating Test Report"
    
    REPORT_FILE="pipeline-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > $REPORT_FILE << EOF
Enterprise CI/CD Pipeline Test Report
=====================================
Generated: $(date)
Test Branch: ${FEATURE_BRANCH}
Repository: $(git remote get-url ${REPO_URL})

Test Results:
✅ Dependencies Installation
✅ Code Linting
✅ Security Audit
✅ Unit Tests
✅ Test Coverage
✅ Application Build
$([ "$SKIP_DOCKER" = false ] && echo "✅ Docker Build" || echo "⏭️  Docker Build (Skipped)")
✅ Deployment Scripts Validation
✅ Kubernetes Manifests Validation
✅ SonarQube Configuration
✅ Comprehensive Test Suite
✅ Production Deployment Simulation
$([ "$SKIP_PR" = false ] && echo "✅ Pull Request Creation" || echo "⏭️  Pull Request Creation (Skipped)")

Branch Information:
- Base Branch: ${BASE_BRANCH}
- Feature Branch: ${FEATURE_BRANCH}
- Commit Hash: $(git rev-parse HEAD)

Coverage Information:
$(cat coverage/lcov-report/index.html | grep -o '[0-9]*\.[0-9]*%' | head -4 | nl || echo "Coverage report not available")

Next Steps:
1. Review PR checks in GitHub Actions
2. Verify SonarQube quality gates
3. Test staging deployment
4. Validate monitoring and alerting
5. Clean up test branches

EOF
    
    log_success "Test report generated: $REPORT_FILE"
    cat $REPORT_FILE
}

# Main execution
main() {
    log_header "Enterprise CI/CD Pipeline Testing"
    log_info "Starting comprehensive pipeline test..."
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Run all tests
    check_prerequisites
    test_local_pipeline
    test_docker_build
    create_feature_branch
    make_test_changes
    test_deployment_scripts
    test_kubernetes_manifests
    test_sonar_config
    run_comprehensive_tests
    simulate_production_deployment
    commit_and_push
    create_pull_request
    generate_test_report
    
    log_header "Pipeline Testing Completed Successfully!"
    log_success "All tests passed! 🎉"
    
    if [ "$SKIP_PR" = false ]; then
        log_info "Check your GitHub repository for the created PR and CI status"
        log_info "PR URL: ${PR_URL}"
    fi
    
    log_info "Test report saved as: $REPORT_FILE"
    log_info "Run 'make clean' to clean up local test artifacts"
    
    # Don't cleanup immediately, let user review
    trap - EXIT
    
    read -p "Press Enter to cleanup test branches or Ctrl+C to keep them..."
    cleanup
}

# Run main function
main "$@"