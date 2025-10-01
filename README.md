# 🚀 Enterprise CI/CD Template

> **Ready to use enterprise-grade CI/CD for your next project? Click "Use this template" above! 👆**

## 🎯 Overview

This is a comprehensive **enterprise-grade CI/CD template** that enforces **zero-human access to production** while maintaining the highest standards of code quality, security, and reliability.

## 📖 How to Use This Template

### Option 1: GitHub Web Interface
1. **Click "Use this template"** button above
2. **Create your new repository**
3. **Follow the [Complete Usage Guide →](./TEMPLATE_USAGE_GUIDE.md)**

### Option 2: GitHub CLI
```bash
gh repo create your-project-name --template pk2731/enterprise-cicd-template --public --clone
cd your-project-name
# Follow the usage guide for setup
```

**👉 [READ THE COMPLETE USAGE GUIDE](./TEMPLATE_USAGE_GUIDE.md) 👈**

## 🌟 Key Features

- **🔒 Zero-Human Production Access** - All deployments are automated
- **📊 Comprehensive Quality Gates** - SonarQube integration with 85% coverage requirement
- **🛡️ Security-First Approach** - Automated vulnerability scanning and secret management
- **☸️ Kubernetes Production Deployments** - Zero-downtime rolling updates
- **📈 Multi-Environment Pipeline** - Dev → Staging → Production workflow
- **🔍 Mandatory Code Reviews** - CODEOWNERS with required approvals
- **📋 Detailed PR Templates** - Comprehensive checklists for all changes

## 🏗️ Architecture

```
Feature Branch → Quality Gates → Build → Dev → Staging → Production
     ↓              ↓            ↓       ↓      ↓         ↓
   PR Created   All Tests     Docker   Docker  Blue-Green  Kubernetes
   Template     Pass          Build    Deploy  Deploy     Rolling Update
   Required     Coverage>80%   Push     Health  E2E Tests  Health Check
   Code Review  Security Scan  Registry Check   Load Test  Auto-Rollback
```

## 📁 Repository Structure

```
├── .github/
│   ├── workflows/
│   │   └── ci-cd.yml              # Main CI/CD pipeline
│   ├── pull_request_template.md   # Mandatory PR checklist
│   ├── CODEOWNERS                 # Required reviewers
│   └── ISSUE_TEMPLATE/
│       └── bug_report.yml         # Structured bug reports
├── k8s/production/
│   ├── namespace.yaml             # Production namespace + policies
│   ├── deployment.yaml            # High-security deployment
│   ├── service.yaml               # Service configuration
│   ├── ingress.yaml               # SSL + security headers
│   ├── configmap.yaml             # Non-sensitive config
│   ├── secret.yaml                # Sensitive data template
│   └── hpa.yaml                   # Auto-scaling configuration
├── scripts/
│   ├── deploy-dev.sh              # Development deployment
│   ├── deploy-staging.sh          # Staging deployment (blue-green)
│   └── health-check.sh            # Universal health checker
├── sonar-project.properties       # SonarQube configuration
└── README.md                      # This file
```

## 🚦 Quality Gates

### ✅ Required Checks (All must pass)
- **Linting** (ESLint/Prettier)
- **Unit Tests** (80%+ coverage)
- **Integration Tests**
- **Security Vulnerability Scan**
- **SonarQube Quality Gate** (85%+ coverage)
- **Performance Tests**
- **Build Verification**

### 🚫 Deployment Blockers
- Failed automated tests
- Security vulnerabilities
- Code coverage below threshold
- Incomplete PR checklist
- Missing required approvals
- Hardcoded secrets detected

## 🚀 Getting Started

### 📖 **Complete Setup Guide**

👉 **[READ THE COMPLETE USAGE GUIDE](./TEMPLATE_USAGE_GUIDE.md)** 👈

For detailed step-by-step instructions on how to use this template, customize it for your project, and set up all the integrations.

### ⚡ Quick Start

1. **Click "Use this template"** → Create new repository
2. **Clone your new repo** locally
3. **Follow the [Template Usage Guide](./TEMPLATE_USAGE_GUIDE.md)** for complete setup
4. **Configure GitHub secrets** for your integrations
5. **Set up branch protection rules** as described in the guide
6. **Start coding** with enterprise-grade CI/CD!

## 🔄 Workflow

### Development Flow
```bash
git checkout -b feature/JIRA-123-new-feature
# Make changes
git commit -m "feat: add new feature"
git push origin feature/JIRA-123-new-feature
# Open PR to develop
```

### Deployment Flow
- **develop** → Automatic deployment to **Development**
- **staging** → Blue-green deployment to **Staging** + E2E tests
- **main** → Zero-downtime Kubernetes deployment to **Production**

## 📊 Monitoring & Observability

### Built-in Health Checks
- Application health endpoints
- Database connectivity
- External service dependencies
- Performance metrics
- Security headers validation

### Automatic Scaling
- **HPA** based on CPU (70%) and Memory (80%)
- **Min replicas**: 3 (high availability)
- **Max replicas**: 20 (load handling)

## 🔒 Security Features

### Production Security
- **Read-only root filesystem**
- **Non-root user execution**
- **Resource limits enforced**
- **Network policies**
- **Security context constraints**

### Secrets Management
- **No hardcoded secrets** in code
- **Kubernetes secrets** for sensitive data
- **Automatic secret scanning**
- **Base64 encoding required**

## 🛠️ Customization

### Adding New Services

1. **Update Kubernetes manifests** in `k8s/production/`
2. **Modify deployment scripts** in `scripts/`
3. **Add health checks** to `scripts/health-check.sh`
4. **Update CODEOWNERS** for new components

### Different Tech Stacks

This template supports:
- **Node.js/TypeScript** (default)
- **Python** (update workflow)
- **Go** (update workflow)
- **Java** (update workflow)

Simply modify `.github/workflows/ci-cd.yml` for your language.

## 🐛 Troubleshooting

### Common Issues

**Quality Gates Failing?**
```bash
# Check SonarQube logs
curl -u token: "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${PROJECT_KEY}"

# Run tests locally
npm run test:coverage
```

**Kubernetes Deployment Issues?**
```bash
# Check deployment status
kubectl rollout status deployment/app-deployment -n production

# View pod logs
kubectl logs -l app=yourapp -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'
```

**GitHub Actions Failing?**
1. Check workflow logs in Actions tab
2. Verify all secrets are set correctly
3. Validate YAML syntax
4. Check branch protection rules

## 📈 Best Practices

### Code Quality
- **Write tests first** (TDD approach)
- **Keep functions small** and focused
- **Document complex logic** with comments
- **Follow naming conventions**

### Security
- **Never commit secrets**
- **Validate all inputs**
- **Use parameterized queries**
- **Keep dependencies updated**

### Performance
- **Monitor response times**
- **Optimize database queries**
- **Use caching strategies**
- **Monitor resource usage**

## 🤝 Contributing

1. **Fork** the template repository
2. **Create** a feature branch
3. **Make** your improvements
4. **Test** thoroughly
5. **Submit** a pull request

## 📄 License

This template is released under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🎉 Success Metrics

With this template, you can expect:

- **🔒 100% Automated Production Deployments**
- **📊 Consistent 85%+ Code Coverage**
- **🛡️ Zero Security Vulnerabilities in Production**
- **⚡ Sub-200ms API Response Times**
- **📈 99.9% Uptime with Auto-scaling**
- **🔄 Zero-downtime Deployments**

**Ready to deploy enterprise-grade applications with confidence!** 🚀