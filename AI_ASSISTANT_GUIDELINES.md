# AI Assistant Guidelines for Robert Consulting Infrastructure Framework

## 🎯 **Purpose**

This document provides specific guidelines for AI assistants working on the Robert Consulting Infrastructure Framework. It complements the main PROJECT_RULES.md and provides AI-specific context and best practices.

---

## 🧠 **Understanding the Project Context**

### **Project Identity**
- **Type**: Production infrastructure framework for a consulting business
- **Owner**: Robert Bailey (rsbailey@necron99.org)
- **Business Model**: Client infrastructure management and consulting services
- **Scale**: Multi-client, multi-account AWS infrastructure

### **Key Business Drivers**
1. **Security**: Client data protection is paramount
2. **Cost**: Competitive pricing requires cost optimization
3. **Reliability**: Client uptime is critical for business
4. **Scalability**: Framework must support multiple clients
5. **Maintainability**: Long-term support and updates

---

## 🔍 **Project Analysis Approach**

### **When Analyzing the Codebase**
1. **Start with README.md** - Understand the overall structure
2. **Check docs/ directory** - Look for existing documentation
3. **Review terraform/ modules** - Understand infrastructure patterns
4. **Examine .github/workflows/** - Understand CI/CD processes
5. **Look at scripts/ directory** - Understand automation patterns

### **Key Files to Always Check**
- `README.md` - Project overview and structure
- `PROJECT_RULES.md` - Project standards and guidelines
- `docs/guides/` - Setup and configuration guides
- `terraform/modules/` - Infrastructure patterns
- `.github/workflows/` - CI/CD processes
- `scripts/README.md` - Available automation scripts

---

## 🛠️ **Development Guidelines**

### **Code Changes**
- **Always follow existing patterns** - Don't reinvent the wheel
- **Use existing scripts** - Leverage automation in `scripts/` directory
- **Follow naming conventions** - kebab-case for files, consistent structure
- **Update documentation** - Keep docs current with changes
- **Test in staging first** - Never deploy directly to production

### **Security Considerations**
- **Security-first approach** - All changes must pass security gates
- **Use existing security tools** - Leverage Semgrep, ESLint, Trivy, CodeQL
- **Follow AWS security best practices** - Encryption, least privilege, monitoring
- **Document security implications** - Explain security impact of changes

### **Infrastructure Changes**
- **Use Terraform modules** - Don't create resources directly
- **Follow existing patterns** - Use established module structure
- **Test with terraform plan** - Always plan before applying
- **Use staging environment** - Test changes in staging first
- **Document resource changes** - Explain infrastructure modifications

---

## 📋 **Common Tasks & Solutions**

### **Adding New Features**
1. **Check existing modules** - Look for similar functionality
2. **Create reusable modules** - Don't duplicate code
3. **Update documentation** - Document new features
4. **Add tests** - Include security and functional tests
5. **Update CI/CD** - Add necessary workflow steps

### **Fixing Security Issues**
1. **Identify the vulnerability** - Understand the security risk
2. **Check existing solutions** - Look for similar fixes
3. **Apply security best practices** - Follow AWS security guidelines
4. **Test the fix** - Verify security improvement
5. **Document the fix** - Explain the security enhancement

### **Deploying Changes**
1. **Use staging pipeline** - Deploy to staging first
2. **Run security scans** - Ensure no new vulnerabilities
3. **Test functionality** - Verify features work correctly
4. **Monitor deployment** - Watch for issues
5. **Document deployment** - Record what was deployed

### **Client Management**
1. **Use client templates** - Leverage existing templates
2. **Follow client patterns** - Use established client structure
3. **Document client setup** - Provide clear instructions
4. **Test client deployment** - Verify client functionality
5. **Monitor client resources** - Ensure client uptime

---

## 🔧 **Tool Usage Guidelines**

### **Terraform**
- **Always use modules** - Don't create resources directly
- **Use consistent naming** - Follow established patterns
- **Plan before apply** - Always run terraform plan first
- **Use state management** - Leverage S3 backend with DynamoDB locking
- **Document variables** - Provide clear variable descriptions

### **GitHub Actions**
- **Use existing workflows** - Don't create new workflows unnecessarily
- **Follow security patterns** - Use established security scanning
- **Test workflows** - Verify workflow functionality
- **Document workflow changes** - Explain workflow modifications
- **Use proper permissions** - Follow least privilege principle

### **AWS Services**
- **Use established patterns** - Follow existing AWS resource patterns
- **Optimize for cost** - Consider cost implications
- **Enable monitoring** - Add appropriate CloudWatch monitoring
- **Use security best practices** - Encryption, access control, logging
- **Document AWS changes** - Explain AWS resource modifications

---

## 📚 **Documentation Standards**

### **When Creating Documentation**
- **Use clear structure** - Follow established documentation patterns
- **Include examples** - Provide code examples and usage instructions
- **Document security implications** - Explain security considerations
- **Keep it current** - Update documentation with changes
- **Use consistent formatting** - Follow established documentation style

### **Documentation Types**
- **Setup guides** - Step-by-step setup instructions
- **Configuration guides** - Configuration options and examples
- **Security documentation** - Security considerations and best practices
- **Deployment guides** - Deployment procedures and troubleshooting
- **API documentation** - API endpoints and usage examples

---

## 🚨 **Error Handling & Troubleshooting**

### **Common Issues**
1. **Terraform state issues** - Use state management scripts
2. **Security scan failures** - Check security tool configurations
3. **Deployment failures** - Use staging environment for testing
4. **Client deployment issues** - Check client template and configuration
5. **AWS permission issues** - Verify IAM roles and policies

### **Troubleshooting Approach**
1. **Check logs** - Review GitHub Actions and AWS CloudWatch logs
2. **Verify configuration** - Check Terraform and workflow configurations
3. **Test in isolation** - Test components individually
4. **Use existing scripts** - Leverage troubleshooting scripts
5. **Document solutions** - Record solutions for future reference

---

## 🔄 **Workflow Integration**

### **GitHub Actions Workflows**
- **Security Scanning** - Automated security vulnerability detection
- **Code Quality** - ESLint, Stylelint, and code analysis
- **Infrastructure** - Terraform plan/apply with state management
- **Deployment** - Staging to production pipeline
- **Issue Management** - Automated issue creation from security findings

### **Workflow Best Practices**
- **Use existing workflows** - Don't create new workflows unnecessarily
- **Follow security patterns** - Use established security scanning
- **Test workflows** - Verify workflow functionality
- **Document workflow changes** - Explain workflow modifications
- **Use proper permissions** - Follow least privilege principle

---

## 🎯 **Success Criteria**

### **Code Quality**
- **Zero ESLint errors** - All code must pass linting
- **Security compliance** - All security scans must pass
- **Documentation coverage** - All changes must be documented
- **Test coverage** - Critical paths must be tested
- **Performance optimization** - Changes must not degrade performance

### **Security**
- **Zero high/critical vulnerabilities** - All security issues must be resolved
- **Security best practices** - Follow AWS security guidelines
- **Access control** - Implement least privilege access
- **Monitoring** - Enable appropriate security monitoring
- **Documentation** - Document security considerations

### **Infrastructure**
- **Terraform compliance** - All infrastructure must be managed by Terraform
- **Cost optimization** - Changes must not increase costs unnecessarily
- **Reliability** - Changes must not impact system reliability
- **Scalability** - Changes must support future growth
- **Maintainability** - Changes must be maintainable long-term

---

## 🔮 **Future Considerations**

### **Technology Evolution**
- **AWS Services** - Stay current with AWS service updates
- **Security Tools** - Adopt new security scanning tools
- **Performance** - Continuous performance optimization
- **Cost** - Ongoing cost optimization initiatives

### **Business Growth**
- **Multi-client support** - Framework must support multiple clients
- **Scalability** - Infrastructure must scale with business growth
- **Automation** - Increase automation to reduce manual effort
- **Monitoring** - Enhance monitoring and alerting capabilities

---

## 📞 **Communication Guidelines**

### **When Reporting Issues**
- **Provide context** - Explain the business impact
- **Include logs** - Provide relevant log information
- **Suggest solutions** - Propose potential solutions
- **Document findings** - Record analysis and recommendations
- **Follow up** - Ensure issues are resolved

### **When Proposing Changes**
- **Explain business value** - Describe the business benefit
- **Consider security implications** - Address security considerations
- **Estimate effort** - Provide effort estimates
- **Document implementation** - Provide implementation details
- **Plan testing** - Include testing strategy

---

**Last Updated**: October 26, 2025  
**Version**: 1.0  
**Maintainer**: Robert Bailey <rsbailey@necron99.org>
