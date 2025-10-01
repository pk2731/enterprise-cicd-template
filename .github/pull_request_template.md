## 📋 Pull Request Checklist

### 🎯 Description
<!-- Provide a brief description of what this PR does -->

**Ticket/Issue**: <!-- Link to JIRA ticket, GitHub issue, etc. -->

**Type of Change**: 
- [ ] 🐛 Bug fix
- [ ] ✨ New feature  
- [ ] 🔧 Refactoring
- [ ] 📚 Documentation
- [ ] 🧪 Tests only
- [ ] 🔒 Security fix

---

## ✅ Pre-Submission Checklist
*All items must be checked before requesting review*

### Code Quality
- [ ] **Self-reviewed**: I have reviewed my own code thoroughly
- [ ] **Linting**: Code passes all linting checks locally
- [ ] **Formatting**: Code is properly formatted (Prettier/Black/gofmt/etc.)
- [ ] **No unused code**: Removed all unused imports, variables, and code
- [ ] **Naming conventions**: Follows team naming standards
- [ ] **Code complexity**: Functions are reasonably sized and focused

### Testing & Coverage
- [ ] **Unit tests**: Added/updated unit tests for new functionality
- [ ] **Integration tests**: Added/updated integration tests if applicable
- [ ] **Test coverage**: Maintains or improves test coverage (>80%)
- [ ] **All tests pass**: All existing and new tests pass locally
- [ ] **Edge cases**: Considered and tested edge cases
- [ ] **Error scenarios**: Tested error handling paths

### Security & Performance
- [ ] **No hardcoded secrets**: No API keys, passwords, or sensitive data in code
- [ ] **Input validation**: All user inputs are validated and sanitized
- [ ] **SQL injection**: Using parameterized queries (if applicable)
- [ ] **XSS prevention**: Proper output encoding (if applicable)
- [ ] **Performance impact**: Considered performance implications
- [ ] **Database queries**: Optimized N+1 queries and added indexes if needed
- [ ] **Memory usage**: No obvious memory leaks or excessive usage

### Documentation & Communication
- [ ] **Code comments**: Added comments for complex logic
- [ ] **Function documentation**: Public functions have proper docstrings
- [ ] **README updated**: Updated documentation if adding new features
- [ ] **API documentation**: Updated API docs if applicable
- [ ] **Breaking changes**: Documented any breaking changes
- [ ] **Migration guide**: Provided migration steps if needed

### Workflow & Process
- [ ] **Branch naming**: Feature branch follows naming convention
- [ ] **Commit messages**: Clear, descriptive commit messages
- [ ] **Dependencies**: New dependencies are justified and approved
- [ ] **Environment variables**: Added any new env vars to documentation
- [ ] **Database changes**: Database migrations are included if needed
- [ ] **Rollback plan**: Considered rollback strategy for risky changes

---

## 🧪 Testing Instructions
<!-- Provide step-by-step instructions for testing this change -->

### Prerequisites
<!-- Any setup required before testing -->

### Test Steps
1. <!-- Step 1 -->
2. <!-- Step 2 -->
3. <!-- Step 3 -->

### Expected Results
<!-- What should happen when following the test steps -->

---

## 📸 Screenshots/Videos
<!-- For UI changes, include before/after screenshots or demo videos -->

---

## 🔄 Related Changes
<!-- List any related PRs, issues, or dependencies -->

- Related PR: #
- Depends on: #
- Blocks: #

---

## 🚨 Deployment Notes
<!-- Any special deployment considerations, env var changes, migrations, etc. -->

### Pre-deployment Checklist
- [ ] **Environment variables**: All required env vars are documented
- [ ] **Database migrations**: Migrations are backwards compatible
- [ ] **Feature flags**: Feature flags configured if applicable
- [ ] **Infrastructure changes**: Any infra changes are documented
- [ ] **Rollback tested**: Rollback procedure has been tested

### Post-deployment Verification
- [ ] **Health checks**: All health check endpoints working
- [ ] **Monitoring**: Relevant metrics are being captured
- [ ] **Logs**: No unexpected errors in logs
- [ ] **Performance**: No performance degradation detected

---

## 🔍 Review Focus Areas
<!-- Guide reviewers on what to focus on -->

- [ ] **Logic correctness**: Is the business logic correct?
- [ ] **Security implications**: Any security concerns?
- [ ] **Performance impact**: Will this affect performance?
- [ ] **Code maintainability**: Is the code easy to understand and maintain?
- [ ] **Test coverage**: Are the tests comprehensive?

---

## ❓ Questions for Reviewers
<!-- Any specific questions or areas where you'd like reviewer input -->

---

## 📋 Reviewer Checklist
*For reviewers to complete*

### Code Review
- [ ] **Logic review**: Business logic is correct and sound
- [ ] **Security review**: No security vulnerabilities introduced
- [ ] **Performance review**: No obvious performance issues
- [ ] **Code style**: Follows team coding standards
- [ ] **Documentation**: Code is well documented
- [ ] **Tests review**: Tests are comprehensive and meaningful

### Final Approval
- [ ] **All discussions resolved**: All review comments addressed
- [ ] **CI checks passed**: All automated checks are passing
- [ ] **Ready for merge**: This PR is ready to be merged

---

**⚠️ Note**: This PR cannot be merged until ALL checklist items are completed and all automated checks pass.