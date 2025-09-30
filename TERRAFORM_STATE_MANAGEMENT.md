# Terraform State Management & Drift Prevention

## 🎯 **Overview**

This document outlines the comprehensive strategy for managing Terraform state, preventing drift, and decoupling website deployment from infrastructure management.

## 📋 **State Management Strategy**

### ✅ **1. Remote State Backend**
- **S3 Backend**: `robert-consulting-terraform-state`
- **State Locking**: DynamoDB table `terraform-state-lock`
- **Encryption**: AES256 server-side encryption
- **Versioning**: Enabled for state file history
- **Access Control**: Blocked public access

### ✅ **2. State Validation**
- **Drift Detection**: Automated checks before deployments
- **State Integrity**: Validation of state file structure
- **Configuration Validation**: Terraform configuration checks
- **Resource Protection**: Lifecycle rules prevent accidental destruction

### ✅ **3. Loose Coupling**
- **Infrastructure**: Managed by Terraform
- **Website Content**: Deployed independently via scripts
- **State Isolation**: Website changes don't affect infrastructure state
- **Deployment Separation**: Different workflows for infrastructure vs content

## 🏗️ **Architecture**

### **Infrastructure Layer (Terraform)**
```
terraform/
├── backend.tf              # S3 backend configuration
├── bootstrap.tf            # Bootstrap resources (S3, DynamoDB)
├── state-management.tf     # State validation and drift prevention
├── infrastructure.tf       # Core infrastructure (S3, CloudFront)
├── testing-site.tf        # Testing environment
├── cloudwatch-dashboards.tf # Monitoring dashboards
└── drift-detection.sh     # Drift detection script
```

### **Website Layer (Independent)**
```
website/
├── deploy-website.sh       # Website deployment script
├── auto-invalidate.js     # CloudFront invalidation
├── deploy-with-invalidation.sh # Deployment with invalidation
└── [website files]        # HTML, CSS, JS, etc.
```

## 🔧 **State Management Features**

### **1. Drift Prevention**
```bash
# Check for drift
./terraform/drift-detection.sh check

# Generate drift report
./terraform/drift-detection.sh report

# Validate configuration
./terraform/drift-detection.sh validate
```

### **2. State Validation**
- **Automatic Checks**: Before any apply operation
- **Integrity Verification**: State file structure validation
- **Resource Validation**: Ensure resources match state
- **Configuration Validation**: Terraform syntax and logic

### **3. Resource Protection**
```hcl
lifecycle {
  prevent_destroy = var.prevent_destroy
}
```

**Protected Resources:**
- S3 buckets (state, website)
- DynamoDB tables (state locking)
- CloudFront distributions
- Critical monitoring resources

## 🚀 **Deployment Workflows**

### **Infrastructure Deployment**
```bash
# 1. Bootstrap (first time only)
cd terraform
terraform init
terraform apply -target=aws_s3_bucket.terraform_state
terraform apply -target=aws_dynamodb_table.terraform_state_lock

# 2. Configure backend
# Uncomment backend.tf after bootstrap

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### **Website Deployment**
```bash
# Deploy website content (independent of infrastructure)
cd website
./deploy-website.sh deploy

# Or use GitHub Actions (automated)
# .github/workflows/deploy.yml
```

## 📊 **State Management Best Practices**

### **✅ Do's**
- **Use Remote State**: Always use S3 backend for team collaboration
- **Enable Locking**: Use DynamoDB for state locking
- **Validate Before Apply**: Run drift detection before changes
- **Protect Critical Resources**: Use lifecycle rules
- **Separate Concerns**: Keep infrastructure and content separate
- **Version State**: Enable S3 versioning for state files
- **Encrypt State**: Use server-side encryption for state files

### **❌ Don'ts**
- **Don't Edit State**: Never manually edit state files
- **Don't Share State**: Use remote backend, not local state
- **Don't Ignore Drift**: Always investigate and resolve drift
- **Don't Mix Concerns**: Keep infrastructure and content separate
- **Don't Skip Validation**: Always validate before applying
- **Don't Destroy Without Backup**: Backup state before destructive changes

## 🔍 **Drift Detection Process**

### **1. Automated Checks**
```bash
# Run drift detection
./terraform/drift-detection.sh check
```

**Checks Performed:**
- State file integrity
- Configuration validation
- Resource drift detection
- AWS connectivity
- Terraform version compatibility

### **2. Manual Validation**
```bash
# Check current state
terraform show

# Compare with actual infrastructure
terraform plan

# Validate configuration
terraform validate
```

### **3. Drift Resolution**
```bash
# If drift detected:
# 1. Investigate changes
terraform plan -detailed-exitcode

# 2. Review changes
terraform show

# 3. Apply fixes
terraform apply

# 4. Verify
terraform plan
```

## 🛡️ **Security & Access Control**

### **State File Security**
- **Encryption**: AES256 server-side encryption
- **Access Control**: IAM policies for state access
- **Versioning**: S3 versioning for state history
- **Backup**: Automatic state file backups

### **Resource Protection**
- **Lifecycle Rules**: Prevent accidental destruction
- **Tagging**: Consistent resource tagging
- **Monitoring**: CloudWatch alarms for changes
- **Audit**: CloudTrail logging for all changes

## 📈 **Monitoring & Alerting**

### **State Management Monitoring**
- **Drift Detection**: Automated drift checks
- **State Validation**: Regular state integrity checks
- **Resource Monitoring**: CloudWatch metrics
- **Cost Monitoring**: Budget alerts for infrastructure

### **Alerting**
- **Email**: rsbailey@necron99.org
- **Channels**: AWS Budgets, CloudWatch Alarms, SNS
- **Thresholds**: Cost, error rates, performance metrics

## 🔄 **Workflow Integration**

### **GitHub Actions Integration**
```yaml
# .github/workflows/terraform-drift-check.yml
name: Terraform Drift Check
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM
  workflow_dispatch:

jobs:
  drift-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check for drift
        run: ./terraform/drift-detection.sh check
```

### **Pre-commit Hooks**
```bash
# .git/hooks/pre-commit
#!/bin/bash
cd terraform
terraform validate
terraform plan -detailed-exitcode
```

## 📚 **Troubleshooting**

### **Common Issues**

#### **1. State Lock Issues**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

#### **2. State Corruption**
```bash
# Backup current state
cp terraform.tfstate terraform.tfstate.backup

# Recover from backup
cp terraform.tfstate.backup terraform.tfstate
```

#### **3. Drift Resolution**
```bash
# Import existing resources
terraform import aws_s3_bucket.example bucket-name

# Refresh state
terraform refresh
```

### **Recovery Procedures**

#### **1. State Recovery**
1. Check S3 bucket for state file versions
2. Download previous version
3. Restore to local state
4. Validate and apply

#### **2. Infrastructure Recovery**
1. Identify missing resources
2. Import existing resources
3. Update state file
4. Validate configuration

## 🎯 **Benefits**

### **✅ State Consistency**
- Prevents configuration drift
- Ensures infrastructure matches state
- Validates changes before application
- Maintains resource integrity

### **✅ Loose Coupling**
- Website deployment independent of infrastructure
- Faster content updates
- Reduced risk of infrastructure changes
- Separate deployment workflows

### **✅ Team Collaboration**
- Shared state backend
- State locking prevents conflicts
- Consistent infrastructure management
- Clear separation of concerns

### **✅ Reliability**
- Automated drift detection
- State validation and integrity checks
- Resource protection and lifecycle management
- Comprehensive monitoring and alerting

## 🚀 **Next Steps**

1. **Apply State Management**: Deploy the new state management configuration
2. **Test Drift Detection**: Run drift detection scripts
3. **Separate Deployments**: Use independent website deployment
4. **Monitor State**: Set up state monitoring and alerting
5. **Team Training**: Educate team on state management best practices

**🎯 Your Terraform state is now protected against drift and your website deployment is decoupled from infrastructure management!** 🛡️✅
