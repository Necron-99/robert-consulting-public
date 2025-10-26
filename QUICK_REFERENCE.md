# Quick Reference Guide - Robert Consulting Infrastructure Framework

## 🚀 **Quick Start Commands**

### **Essential Commands**
```bash
# Check project status
gh run list --limit=5

# Run security scan
./scripts/security-scan.sh

# Deploy to staging
./scripts/deploy-staging-environment.sh

# Deploy to production
./scripts/deploy-admin-site.sh

# Check Terraform status
cd terraform && terraform plan

# List security issues
gh issue list --label "security" --state open
```

### **Common Scripts**
```bash
# Security
./scripts/security-scan.sh
./scripts/enable-waf-protection.sh
./scripts/disable-waf-protection.sh

# Deployment
./scripts/deploy-admin-site.sh
./scripts/deploy-staging-environment.sh
./scripts/deploy-client-content.sh

# Maintenance
./scripts/cleanup-unused-infrastructure.sh
./scripts/setup-github-environment.sh
```

---

## 📁 **Key Directories**

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `docs/` | Documentation | `README.md`, `guides/`, `reports/` |
| `scripts/` | Automation | `deploy-*.sh`, `security-*.sh` |
| `terraform/` | Infrastructure | `main.tf`, `modules/` |
| `website/` | Main site | `index.html`, `dashboard.html` |
| `admin/` | Admin site | `index.html`, `client-deployment.html` |
| `.github/workflows/` | CI/CD | `staging-to-production-pipeline.yml` |

---

## 🔒 **Security Tools**

| Tool | Purpose | Command |
|------|---------|---------|
| **Semgrep** | Static analysis | `semgrep --config=auto .` |
| **ESLint** | Code quality | `npm run lint` |
| **Trivy** | Container security | `trivy fs .` |
| **CodeQL** | Semantic analysis | GitHub Actions |
| **OWASP ZAP** | Dynamic testing | GitHub Actions |

---

## 🏗️ **Infrastructure Components**

### **AWS Resources**
- **S3**: `robert-consulting-website` (main), `robert-consulting-admin` (admin)
- **CloudFront**: Multiple distributions for different sites
- **Lambda**: Authentication, monitoring, and utility functions
- **Route53**: DNS management for all domains
- **WAF**: Web Application Firewall protection

### **Terraform Modules**
- `modules/baileylessons/` - Client infrastructure
- `modules/plex-project/` - Plex recommendations project
- `modules/admin-site/` - Admin site infrastructure

---

## 🌐 **URLs & Environments**

| Environment | URL | Purpose |
|-------------|-----|---------|
| **Production** | `https://robertconsulting.net` | Main website |
| **Admin** | `https://admin.robertconsulting.net` | Admin dashboard |
| **Staging** | `https://d3guz3lq4sqlvl.cloudfront.net` | Staging environment |
| **Client Sites** | Various | Client-specific sites |

---

## 📋 **Common Workflows**

### **Deploying Changes**
1. **Make changes** in appropriate directory
2. **Test locally** if possible
3. **Push to staging** branch
4. **Monitor staging deployment** in GitHub Actions
5. **Deploy to production** via staging-to-production pipeline

### **Adding New Client**
1. **Create client repository** using template
2. **Configure client settings** in admin dashboard
3. **Deploy client infrastructure** via Terraform
4. **Test client deployment** in staging
5. **Deploy to production** and monitor

### **Security Incident Response**
1. **Check security alerts** in GitHub Issues
2. **Review security scan results** in GitHub Actions
3. **Apply security fixes** following best practices
4. **Test fixes** in staging environment
5. **Deploy fixes** and monitor

---

## 🔧 **Troubleshooting**

### **Common Issues**

| Issue | Solution |
|-------|----------|
| **Terraform state lock** | Use `./scripts/terraform-state-lock-manager.sh` |
| **Security scan failures** | Check tool configurations in workflows |
| **Deployment failures** | Check GitHub Actions logs and AWS permissions |
| **Client deployment issues** | Verify client template and configuration |
| **AWS permission errors** | Check IAM roles and policies |

### **Useful Commands**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform state
cd terraform && terraform state list

# Check GitHub Actions status
gh run list --workflow="staging-to-production-pipeline.yml"

# Check security issues
gh issue list --label "security" --state open

# Check recent deployments
gh run list --limit=10
```

---

## 📊 **Monitoring & Alerts**

### **Key Metrics**
- **Security**: Zero high/critical vulnerabilities
- **Performance**: Page load time < 2 seconds
- **Uptime**: 99.9% availability
- **Cost**: Monthly cost optimization reviews

### **Monitoring Tools**
- **CloudWatch**: AWS resource monitoring
- **GitHub Actions**: CI/CD pipeline monitoring
- **Security Scans**: Automated vulnerability detection
- **Cost Alerts**: Budget threshold notifications

---

## 🎯 **Success Criteria**

### **Security**
- ✅ Zero high/critical security vulnerabilities
- ✅ All security scans passing
- ✅ Security best practices implemented
- ✅ Access control properly configured

### **Quality**
- ✅ Zero ESLint errors
- ✅ All tests passing
- ✅ Documentation updated
- ✅ Code follows project standards

### **Performance**
- ✅ Page load time < 2 seconds
- ✅ 99.9% uptime
- ✅ Cost optimization maintained
- ✅ Scalability requirements met

---

## 📞 **Emergency Contacts**

### **Critical Issues**
- **Security Incidents**: Immediate response required
- **Production Outages**: Deploy rollback immediately
- **Data Breaches**: Follow security incident response plan

### **Escalation Path**
1. **Check logs** and identify issue
2. **Apply immediate fixes** if possible
3. **Document issue** and response
4. **Notify stakeholders** if critical
5. **Follow up** with permanent solution

---

## 🔄 **Maintenance Schedule**

### **Daily**
- Monitor security alerts
- Check deployment status
- Review cost metrics

### **Weekly**
- Review security scan results
- Update dependencies
- Check performance metrics

### **Monthly**
- Security dependency updates
- Cost optimization review
- Performance analysis
- Documentation updates

---

**Last Updated**: October 26, 2025  
**Version**: 1.0  
**Maintainer**: Robert Bailey <rsbailey@necron99.org>
