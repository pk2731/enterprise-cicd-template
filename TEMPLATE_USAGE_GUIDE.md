# 📋 How to Use This Enterprise CI/CD Template

## 🎯 Quick Start Guide

This template provides you with a complete **enterprise-grade CI/CD pipeline** that enforces zero-human production access while maintaining the highest standards of code quality and security.

---

## 🚀 Step 1: Create Your Project from Template

### Option A: Using GitHub Web Interface
1. **Go to**: https://github.com/pk2731/enterprise-cicd-template
2. **Click**: `Use this template` → `Create a new repository`
3. **Fill in**:
   - Repository name: `your-awesome-project`
   - Description: Brief description of your project
   - Visibility: Public or Private
4. **Click**: `Create repository from template`

### Option B: Using GitHub CLI
```bash
gh repo create your-awesome-project --template pk2731/enterprise-cicd-template --public --clone
cd your-awesome-project
```

---

## ⚙️ Step 2: Customize for Your Project

### 2.1 Update Project Information

**Edit these files with your project details:**

```bash
# Update package.json
vim package.json
# Change: name, description, author, repository URL

# Update SonarQube configuration  
vim sonar-project.properties
# Change: projectKey, projectName, github.repository

# Update Kubernetes manifests
vim k8s/production/*.yaml
# Change: app names, domains, resource limits

# Update CODEOWNERS
vim .github/CODEOWNERS
# Replace @team-names with your actual GitHub usernames/teams
```

### 2.2 Technology Stack Customization

**For Node.js Projects** (Default - Ready to use):
- ✅ Already configured
- Update `package.json` dependencies as needed

**For Python Projects**:
```bash
# Update .github/workflows/ci-cd.yml
# Replace Node.js setup with Python setup:

- name: Setup Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.11'

- name: Install dependencies
  run: |
    pip install -r requirements.txt
    pip install pytest coverage flake8

- name: Run tests
  run: |
    pytest --cov=src --cov-report=xml
    coverage xml

# Update sonar-project.properties
sonar.sources=src
sonar.tests=tests
sonar.python.coverage.reportPaths=coverage.xml
```

**For Java Projects**:
```bash
# Update .github/workflows/ci-cd.yml
# Replace Node.js setup with Java setup:

- name: Setup JDK
  uses: actions/setup-java@v3
  with:
    java-version: '17'
    distribution: 'temurin'

- name: Run tests
  run: ./mvnw clean test

- name: Build
  run: ./mvnw clean package
```

**For Go Projects**:
```bash
# Update .github/workflows/ci-cd.yml
# Replace Node.js setup with Go setup:

- name: Setup Go
  uses: actions/setup-go@v4
  with:
    go-version: '1.21'

- name: Run tests
  run: |
    go test -v -coverprofile=coverage.out ./...
    go tool cover -func=coverage.out
```

---

## 🔐 Step 3: Configure GitHub Repository Settings

### 3.1 Enable Required Features

**Go to Settings → General:**
- ✅ Enable Issues
- ✅ Enable Discussions (optional)
- ✅ Enable Actions
- ❌ Disable Wiki (unless needed)

### 3.2 Set Up Branch Protection Rules

**Go to Settings → Branches and add rules:**

#### Main Branch (Production)
```yaml
Branch name pattern: main
Protect matching branches:
  ✅ Require a pull request before merging
    ✅ Require approvals: 2
    ✅ Dismiss stale PR approvals when new commits are pushed
    ✅ Require review from code owners
    ✅ Require approval of the most recent reviewers
  ✅ Require status checks to pass before merging
    ✅ Require branches to be up to date before merging
    Required status checks:
      - quality-gates
      - build-and-push  
      - SonarQube Quality Gate
  ✅ Require conversation resolution before merging
  ✅ Restrict pushes that create files larger than 100MB
  ✅ Do not allow bypassing the above settings (even for admins)
```

#### Staging Branch
```yaml
Branch name pattern: staging
Protect matching branches:
  ✅ Require a pull request before merging
    ✅ Require approvals: 1
    ✅ Require review from code owners
  ✅ Require status checks to pass before merging
    Required status checks:
      - quality-gates
      - build-and-push
```

#### Development Branch
```yaml
Branch name pattern: develop
Protect matching branches:
  ✅ Require a pull request before merging
    ✅ Require approvals: 1
  ✅ Require status checks to pass before merging
    Required status checks:
      - quality-gates
```

---

## 🔑 Step 4: Configure Secrets

### 4.1 Required Secrets

**Go to Settings → Secrets and variables → Actions:**

#### SonarQube Integration
```bash
# Get from your SonarQube/SonarCloud account
SONAR_TOKEN=squ_1234567890abcdef...
SONAR_HOST_URL=https://sonarcloud.io  # or your self-hosted URL
```

#### AWS/Kubernetes (for Production Deployment)
```bash
# AWS credentials with EKS access
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-west-2
EKS_CLUSTER_NAME=your-production-cluster
```

#### Deployment Servers
```bash
# Development server
DEV_SERVER_HOST=dev.yourproject.com
DEV_SERVER_USER=deploy
DEV_SERVER_KEY=-----BEGIN PRIVATE KEY-----...

# Staging server
STAGING_SERVER_HOST=staging.yourproject.com
STAGING_SERVER_USER=deploy
STAGING_SERVER_KEY=-----BEGIN PRIVATE KEY-----...
STAGING_DB_HOST=staging-db.yourproject.com
STAGING_DB_PORT=5432
STAGING_DATABASE_URL=postgresql://user:pass@host:port/db
```

#### Notifications
```bash
# Microsoft Teams webhook for notifications
TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...

# Monitoring system webhook
MONITORING_WEBHOOK_URL=https://your-monitoring-system.com/webhook
```

### 4.2 Optional Secrets
```bash
# Code coverage
CODECOV_TOKEN=your_codecov_token

# Container registry (if not using GitHub Container Registry)
DOCKER_REGISTRY=your-registry.com
DOCKER_USERNAME=your-username  
DOCKER_PASSWORD=your-password

# External services
SLACK_WEBHOOK_URL=https://hooks.slack.com/...
DATADOG_API_KEY=your_datadog_key
```

---

## 📊 Step 5: Set Up SonarQube/SonarCloud

### 5.1 SonarCloud Setup (Recommended for Open Source)

1. **Go to**: https://sonarcloud.io
2. **Login** with GitHub account
3. **Import** your repository
4. **Configure** quality gate:
   - Go to Quality Gates → Create
   - Name: "Strict Production Gate"
   - Add conditions:
     - Coverage on new code ≥ 85%
     - Duplicated lines on new code ≤ 3%
     - Maintainability rating on new code = A
     - Reliability rating on new code = A
     - Security rating on new code = A
     - Security hotspots reviewed = 100%
5. **Generate** token: Account → Security → Generate Token
6. **Add** `SONAR_TOKEN` to GitHub repository secrets

### 5.2 Self-Hosted SonarQube

1. **Install** SonarQube on your server
2. **Create** new project
3. **Configure** webhook: Administration → Webhooks
   - URL: `https://api.github.com/repos/owner/repo/statuses/{sha}`
   - Secret: Your GitHub webhook secret
4. **Set up** quality gate with same conditions as above

---

## ☸️ Step 6: Configure Kubernetes (Production)

### 6.1 Update Kubernetes Manifests

**Edit `k8s/production/*.yaml` files:**

```yaml
# deployment.yaml
metadata:
  name: your-app-deployment  # Change app name
spec:
  replicas: 3  # Adjust based on your needs
  template:
    spec:
      containers:
      - name: app
        image: IMAGE_TAG_PLACEHOLDER
        resources:
          requests:
            cpu: 200m      # Adjust based on your app
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi

# ingress.yaml
spec:
  tls:
  - hosts:
    - yourapp.com        # Change to your domain
    - www.yourapp.com
    secretName: your-app-tls-secret
  rules:
  - host: yourapp.com    # Change to your domain
```

### 6.2 Create Kubernetes Secrets

**Run these commands on your Kubernetes cluster:**

```bash
# Create production namespace
kubectl create namespace production

# Create application secrets
kubectl create secret generic app-secrets \
  --from-literal=DATABASE_URL="your-db-url" \
  --from-literal=JWT_SECRET="your-jwt-secret" \
  --namespace=production

# Create Docker registry secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=your-github-username \
  --docker-password=your-github-token \
  --docker-email=your-email \
  --namespace=production
```

---

## 🔄 Step 7: Development Workflow

### 7.1 Branch Strategy

```bash
# Create feature branch from develop
git checkout develop
git pull origin develop  
git checkout -b feature/JIRA-123-new-feature

# Make your changes
# ... code, test, commit ...

# Push and create PR to develop
git push origin feature/JIRA-123-new-feature
# Create PR via GitHub UI: feature/branch → develop
```

### 7.2 PR Process

1. **Complete PR Template** - All checkboxes must be filled
2. **Wait for Quality Gates** - All automated checks must pass
3. **Code Review** - Get required approvals from CODEOWNERS
4. **Merge to Develop** - Triggers development deployment
5. **Test in Development** - Verify your changes work
6. **PR to Staging** - Create PR from develop → staging
7. **Test in Staging** - E2E tests and performance validation
8. **PR to Main** - Create PR from staging → main (production)

### 7.3 Deployment Flow

```
Feature Branch → Develop → Staging → Main
     ↓             ↓         ↓        ↓
  PR Created   Dev Deploy  Blue-Green  Kubernetes
  Quality Gates Health Check E2E Tests  Rolling Update
  Code Review   Basic Tests Load Tests  Auto-Rollback
```

---

## 🧪 Step 8: Testing Your Setup

### 8.1 Create Test Branches

```bash
# Create develop and staging branches
git checkout -b develop
git push origin develop

git checkout -b staging  
git push origin staging

# Create a feature branch to test the pipeline
git checkout develop
git checkout -b test/pipeline-validation
```

### 8.2 Test Quality Gates

**Add a simple test file:**

```javascript
// src/app.test.js
const request = require('supertest');
const app = require('./app');

describe('GET /health', () => {
  it('should return 200 OK', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});
```

**Create a simple app:**

```javascript
// src/app.js
const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready' });
});

module.exports = app;
```

### 8.3 Validate Pipeline

```bash
# Commit and push test changes
git add .
git commit -m "test: validate CI/CD pipeline"
git push origin test/pipeline-validation

# Create PR to develop
gh pr create --title "Test: Validate CI/CD Pipeline" --body "Testing the complete pipeline setup"
```

**Expected Results:**
- ✅ ESLint check passes
- ✅ Prettier formatting passes  
- ✅ Unit tests pass (80%+ coverage)
- ✅ Security audit passes
- ✅ Build verification passes
- ⚠️ SonarQube might fail initially (need to configure)

---

## 🛠️ Step 9: Customization Examples

### 9.1 Add Database Migrations

**Update `.github/workflows/ci-cd.yml`:**

```yaml
# Add after "Install dependencies"
- name: Run Database Migrations
  run: npm run migrate
  env:
    DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}
```

### 9.2 Add Custom Health Checks

**Update `scripts/health-check.sh`:**

```bash
# Add custom endpoint checks
CUSTOM_ENDPOINTS=(
    "$BASE_URL/api/custom/health"
    "$BASE_URL/api/payment/status"
)

for endpoint in "${CUSTOM_ENDPOINTS[@]}"; do
    # ... health check logic
done
```

### 9.3 Add Performance Budgets

**Update workflow:**

```yaml
- name: Performance Budget Check
  run: |
    npm run build
    npx bundlesize
```

### 9.4 Add Security Scanning

**Add to workflow:**

```yaml
- name: Security Scan with Snyk
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. SonarQube Quality Gate Failing
```bash
# Check coverage locally
npm run test:coverage

# View detailed coverage report
open coverage/lcov-report/index.html

# Fix: Add more tests to reach 85% coverage
```

#### 2. Branch Protection Preventing Merge
```bash
# Ensure all required checks are passing
gh pr checks

# Check if you have required approvals
gh pr view --json reviewDecision
```

#### 3. Kubernetes Deployment Failing
```bash
# Check cluster access
kubectl auth can-i create deployments --namespace=production

# Verify secrets exist
kubectl get secrets -n production

# Check pod logs
kubectl logs -l app=yourapp -n production
```

#### 4. Docker Build Failing
```bash
# Test build locally
docker build -t test .

# Check Dockerfile syntax
docker build --no-cache -t test .
```

---

## 📈 Best Practices

### Code Quality
- **Write tests first** (TDD approach)
- **Maintain 85%+ coverage** on new code
- **Keep functions small** (< 20 lines)
- **Use descriptive variable names**
- **Add JSDoc comments** for public APIs

### Security
- **Never commit secrets** to repository
- **Use environment variables** for configuration  
- **Keep dependencies updated** regularly
- **Review security alerts** promptly
- **Use least-privilege principle** for access

### Performance
- **Monitor bundle sizes** and loading times
- **Use caching strategies** appropriately
- **Optimize database queries**
- **Set up performance budgets**
- **Monitor memory usage**

### DevOps
- **Keep deployment scripts simple**
- **Test rollback procedures** regularly
- **Monitor application metrics**
- **Set up proper alerting**
- **Document deployment processes**

---

## 🎉 Success Metrics

After implementing this template, you should see:

- **🔒 100% Zero-Human Production Deployments**
- **📊 Consistent 85%+ Code Coverage**  
- **🛡️ Zero Security Vulnerabilities in Production**
- **⚡ Fast Development Cycle** (< 10 min from commit to deployment)
- **📈 99.9% Uptime** with auto-scaling and rollbacks
- **🔄 Zero-Downtime Deployments**
- **👥 Consistent Code Quality** across all team members

---

## 💡 Advanced Features

### Multi-Environment Secrets Management
- Use different secret sets per environment
- Implement secret rotation policies
- Use external secret management (AWS Secrets Manager, etc.)

### Advanced Monitoring
- Set up distributed tracing
- Implement custom metrics
- Create dashboards for business KPIs
- Set up alerting rules

### Compliance Features
- Add compliance checks to pipeline
- Implement audit logging
- Generate compliance reports
- Set up data retention policies

---

## 🤝 Contributing to This Template

If you find improvements or have suggestions:

1. Fork this template repository
2. Create a feature branch
3. Make your improvements
4. Test with multiple project types
5. Submit a pull request

---

## 📞 Support

If you encounter issues:
1. Check this guide first
2. Search existing GitHub issues
3. Create a detailed issue report
4. Include logs and configuration details

---

**🚀 You're now ready to build enterprise-grade applications with confidence!**