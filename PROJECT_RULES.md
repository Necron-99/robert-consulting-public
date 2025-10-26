# Robert Consulting Infrastructure Framework - Project Rules

## 🎯 **Project Overview**

This is a **production-ready serverless infrastructure framework** for Robert Consulting that provides complete AWS infrastructure-as-code with built-in security, monitoring, and cost optimization. The project serves as both a client management system and a showcase of best practices.

**Core Principles**: High Security, High Maintainability, Low Cost

---

## 🏗️ **Architecture & Structure**

### **Project Type**
- **Infrastructure**: AWS serverless (S3 + CloudFront + Lambda + Route53)
- **Frontend**: Vanilla HTML/CSS/JavaScript (no frameworks)
- **Backend**: AWS Lambda functions
- **Infrastructure as Code**: Terraform with modular design
- **Deployment**: GitHub Actions CI/CD pipelines

### **Directory Structure Rules**
```
robert-consulting-public/
├── docs/                    # 📚 All documentation (guides, reports, security)
├── scripts/                 # 🔧 Automation scripts (deployment, security, utilities)
├── config/                  # ⚙️ Configuration files (terraform, aws, github)
├── website/                 # 🌐 Main website content (HTML, CSS, JS)
├── admin/                   # 🔐 Admin site and client management
├── terraform/               # 🏗️ Infrastructure as Code
├── .github/workflows/       # 🤖 GitHub Actions CI/CD
├── skeleton-client/         # 📋 Client template
├── client-template/         # 📋 Client template
├── client-content-template/ # 📋 Content template
└── lambda/                  # ⚡ Lambda functions
```

### **File Naming Conventions**
- **Scripts**: `kebab-case.sh` (e.g., `deploy-admin-site.sh`)
- **Terraform**: `kebab-case.tf` (e.g., `admin-enhanced-security.tf`)
- **Workflows**: `kebab-case.yml` (e.g., `staging-to-production-pipeline.yml`)
- **Documentation**: `UPPER_CASE.md` (e.g., `SECURITY_IMPLEMENTATION.md`)

---

## 🔒 **Security Standards**

### **Security-First Approach**
- **All changes must pass security gates** before deployment
- **Zero tolerance for high/critical security vulnerabilities**
- **Comprehensive security scanning** (Semgrep, ESLint, Trivy, CodeQL, OWASP ZAP)
- **Automated security issue management** with closed-loop feedback

### **AWS Security Requirements**
- **S3**: Server-side encryption (AES256), versioning, public access blocked
- **CloudFront**: OAC for S3 access, HTTPS redirect, TLS 1.2+ minimum
- **Lambda**: X-Ray tracing enabled, least privilege IAM roles
- **Secrets**: AWS Secrets Manager for sensitive data
- **WAF**: Protection enabled for all public-facing resources

### **Authentication & Access Control**
- **Basic Auth** for admin access via CloudFront Functions
- **IP restrictions** for sensitive operations
- **Session management** with JWT tokens
- **Audit logging** for all admin actions

### **Security Scanning Tools**
- **Semgrep**: Static analysis for security vulnerabilities
- **ESLint**: Code quality and security rules
- **Trivy**: Container and infrastructure security scanning
- **CodeQL**: GitHub's semantic code analysis
- **OWASP ZAP**: Dynamic application security testing

---

## 💰 **Cost Optimization Standards**

### **AWS Cost Management**
- **CloudFront**: PriceClass_100 (US, Canada, Europe only)
- **S3**: Intelligent Tiering for storage optimization
- **Lambda**: Optimized memory allocation (256MB default)
- **Monitoring**: Cost alerts and budget tracking
- **Resource cleanup**: Automated removal of unused resources

### **Resource Efficiency**
- **Single-purpose resources** (avoid over-provisioning)
- **Lifecycle policies** for data retention
- **Minimal monitoring** (only essential metrics)
- **No unnecessary features** enabled

---

## 🔧 **Development Standards**

### **Code Quality**
- **ESLint**: Enforced code quality rules
- **Stylelint**: CSS formatting standards
- **TypeScript**: ES modules (`"type": "module"`)
- **Node.js**: Version 18+ required

### **ESLint Rules**
- **Security**: `eslint-plugin-security`, `eslint-plugin-no-secrets`
- **Code Quality**: `camelCase`, `curly braces`, `single quotes`
- **Best Practices**: `no-unused-vars`, `no-undef`, `no-console`

### **CSS Standards**
- **Stylelint**: Standard configuration with custom rules
- **Indentation**: 2 spaces
- **Max line length**: 120 characters
- **Color format**: Lowercase hex, short format
- **No vendor prefixes**: Use autoprefixer

### **Terraform Standards**
- **Modular design**: Reusable modules in `terraform/modules/`
- **Consistent tagging**: All resources tagged with `Name`, `Environment`, `Project`, `ManagedBy`
- **State management**: S3 backend with DynamoDB locking
- **Variable validation**: Type constraints and descriptions
- **Output documentation**: Clear output descriptions

---

## 🚀 **Deployment & CI/CD**

### **Deployment Pipeline**
1. **Staging**: All changes go to staging first
2. **Security Gates**: Comprehensive security scanning
3. **Quality Gates**: Code quality and functionality tests
4. **Production**: Manual approval required for production
5. **Rollback**: Automated rollback on failure

### **GitHub Actions Workflows**
- **Security Scanning**: Automated security vulnerability detection
- **Code Quality**: ESLint, Stylelint, and code analysis
- **Infrastructure**: Terraform plan/apply with state management
- **Deployment**: Staging to production pipeline
- **Issue Management**: Automated issue creation from security findings

### **Environment Management**
- **Staging**: `d3guz3lq4sqlvl.cloudfront.net`
- **Production**: `robertconsulting.net`
- **Admin**: `admin.robertconsulting.net`
- **Client Sites**: Separate CloudFront distributions

---

## 📋 **Client Management**

### **Client Templates**
- **skeleton-client/**: Complete client infrastructure template
- **client-template/**: Content deployment template
- **client-content-template/**: Content-only template

### **Client Deployment Process**
1. **Repository Setup**: Client creates GitHub repository
2. **Content Development**: Client develops content locally
3. **Automated Deployment**: Content synced to S3 via GitHub Actions
4. **Infrastructure Management**: Terraform manages AWS resources
5. **Monitoring**: Automated monitoring and alerting

### **Multi-Account Strategy**
- **Main Account**: Robert Consulting infrastructure
- **Client Accounts**: Separate AWS accounts for client isolation
- **Cross-Account Roles**: Secure access between accounts

---

## 📚 **Documentation Standards**

### **Documentation Structure**
- **docs/guides/**: Setup and configuration guides
- **docs/reports/**: Analysis and summary reports
- **docs/deployment/**: Deployment documentation
- **docs/security/**: Security documentation
- **docs/infrastructure/**: Infrastructure documentation

### **Documentation Requirements**
- **README.md**: Required for all major directories
- **Clear examples**: Code examples and usage instructions
- **Version information**: Keep documentation current
- **Security notes**: Document security considerations

---

## 🧪 **Testing & Quality Assurance**

### **Testing Strategy**
- **Security Testing**: Automated security scanning
- **Functional Testing**: Manual testing of key features
- **Performance Testing**: CloudFront and S3 performance monitoring
- **Integration Testing**: End-to-end workflow testing

### **Quality Gates**
- **Zero high/critical security vulnerabilities**
- **All ESLint errors resolved**
- **All tests passing**
- **Documentation updated**

---

## 🔄 **Maintenance & Operations**

### **Regular Maintenance**
- **Security Updates**: Monthly security dependency updates
- **Cost Reviews**: Monthly cost optimization reviews
- **Performance Monitoring**: Continuous performance monitoring
- **Backup Verification**: Regular backup testing

### **Monitoring & Alerting**
- **CloudWatch**: AWS resource monitoring
- **Cost Alerts**: Budget threshold alerts
- **Security Alerts**: Automated security issue notifications
- **Performance Alerts**: Performance degradation alerts

---

## 🚨 **Emergency Procedures**

### **Security Incidents**
1. **Immediate Response**: Disable affected resources
2. **Investigation**: Analyze security logs and impact
3. **Remediation**: Apply security fixes
4. **Documentation**: Document incident and response
5. **Prevention**: Update security measures

### **Deployment Failures**
1. **Rollback**: Immediate rollback to previous version
2. **Investigation**: Analyze failure logs
3. **Fix**: Apply necessary fixes
4. **Re-deployment**: Deploy fixed version
5. **Monitoring**: Enhanced monitoring post-deployment

---

## 📞 **Communication & Collaboration**

### **Issue Management**
- **GitHub Issues**: Primary issue tracking
- **Security Issues**: Automated creation from security scans
- **Labels**: Consistent labeling system (`security`, `bug`, `enhancement`)
- **Milestones**: Project milestone tracking

### **Code Review**
- **Pull Requests**: All changes via pull requests
- **Security Review**: Security-focused code review
- **Documentation Review**: Ensure documentation is updated
- **Testing Review**: Verify tests are adequate

---

## 🎯 **Success Metrics**

### **Security Metrics**
- **Zero high/critical vulnerabilities**
- **100% security scan coverage**
- **Mean time to remediation < 24 hours**

### **Quality Metrics**
- **Zero ESLint errors**
- **100% test coverage for critical paths**
- **Documentation coverage > 90%**

### **Performance Metrics**
- **Page load time < 2 seconds**
- **99.9% uptime**
- **Cost optimization > 20% savings**

### **Operational Metrics**
- **Deployment success rate > 95%**
- **Mean time to recovery < 1 hour**
- **Customer satisfaction > 90%**

---

## 🔮 **Future Considerations**

### **Technology Evolution**
- **AWS Services**: Stay current with AWS service updates
- **Security Tools**: Adopt new security scanning tools
- **Performance**: Continuous performance optimization
- **Cost**: Ongoing cost optimization initiatives

### **Scalability Planning**
- **Multi-region**: Plan for multi-region deployment
- **Auto-scaling**: Implement auto-scaling where appropriate
- **Load Balancing**: Plan for increased traffic
- **Database**: Consider database solutions for complex data

---

**Last Updated**: October 26, 2025  
**Version**: 1.0  
**Maintainer**: Robert Bailey <rsbailey@necron99.org>
