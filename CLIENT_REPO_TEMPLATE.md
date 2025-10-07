# Client Repository Template

## Repository Structure

```
client-name-infrastructure/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       ├── deploy-infrastructure.yml
│       ├── deploy-content.yml
│       └── drift-check.yml
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       └── client-infrastructure/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── content/
│   ├── website/
│   │   ├── index.html
│   │   ├── css/
│   │   ├── js/
│   │   └── assets/
│   └── deploy.sh
└── docs/
    ├── DEPLOYMENT.md
    ├── INFRASTRUCTURE.md
    └── TROUBLESHOOTING.md
```

## Key Features

### Infrastructure Management
- **Terraform-based**: Uses shared client-infrastructure module
- **State management**: Remote S3 backend with DynamoDB locking
- **Cross-account**: Assumes roles in client AWS account
- **Adopt existing resources**: Can adopt existing CloudFront/Route53/ACM

### Content Management
- **Separate deployment**: Content updates don't require infrastructure changes
- **Automated CI/CD**: GitHub Actions for content deployment
- **CloudFront invalidation**: Automatic cache clearing on updates

### Security & Monitoring
- **Least privilege**: Minimal IAM permissions for client account
- **Cost monitoring**: Budget alerts and cost dashboards
- **Drift detection**: Automated infrastructure drift checking

## Setup Instructions

### 1. Repository Creation
```bash
# Create new repository
gh repo create client-name-infrastructure --private

# Clone and initialize
git clone https://github.com/your-org/client-name-infrastructure.git
cd client-name-infrastructure
```

### 2. Infrastructure Setup
```bash
# Copy template files
cp -r /path/to/skeleton-client/* infrastructure/

# Configure client-specific settings
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with client details
```

### 3. Content Setup
```bash
# Create content directory
mkdir -p content/website

# Add client website files
# Copy existing website content to content/website/
```

### 4. CI/CD Configuration
```bash
# Copy GitHub Actions workflows
cp -r .github/workflows/* .github/workflows/

# Configure secrets in GitHub repository:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - CLIENT_ACCOUNT_ID
# - MANAGEMENT_ACCOUNT_ID
```

## Client-Specific Configuration

### terraform.tfvars
```hcl
# Client Information
client_name        = "client-name"
client_domain      = "client-domain.com"
aws_region         = "us-east-1"
environment        = "production"

# Additional domains
additional_domains = ["www.client-domain.com", "app.client-domain.com"]

# Existing resources (if adopting)
existing_cloudfront_distribution_id = "E..."
existing_route53_zone_id            = "Z..."
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:...:certificate/..."

# Features
enable_cloudfront  = true
enable_waf         = true
enable_monitoring  = true
```

### GitHub Secrets Required
- `AWS_ACCESS_KEY_ID`: Management account credentials
- `AWS_SECRET_ACCESS_KEY`: Management account credentials
- `CLIENT_ACCOUNT_ID`: Target client AWS account ID
- `MANAGEMENT_ACCOUNT_ID`: Your management account ID

## Deployment Workflows

### Infrastructure Deployment
- **Trigger**: Manual or on infrastructure changes
- **Process**: Terraform plan → apply in client account
- **State**: Stored in management account S3 backend

### Content Deployment
- **Trigger**: Push to main branch
- **Process**: Sync content to S3 → invalidate CloudFront
- **Frequency**: Can be automated for content updates

### Drift Detection
- **Trigger**: Daily schedule
- **Process**: Check for infrastructure drift
- **Alerts**: Notify on drift detection

## Security Considerations

### IAM Roles in Client Account
- `RobertClientDeploymentRole`: For infrastructure management
- `RobertConsoleAccessRole`: For console access (optional)

### Network Security
- WAF rules for DDoS protection
- Rate limiting and security headers
- HTTPS enforcement

### Monitoring
- Cost alerts and budget monitoring
- Performance metrics and dashboards
- Security scanning and vulnerability detection

## Troubleshooting

### Common Issues
1. **State lock conflicts**: Check DynamoDB lock table
2. **Permission errors**: Verify IAM role assumptions
3. **Resource conflicts**: Check for existing resources
4. **DNS propagation**: Allow time for DNS changes

### Recovery Procedures
1. **State corruption**: Restore from S3 versioning
2. **Resource drift**: Import existing resources
3. **Deployment failures**: Check CloudWatch logs

## Best Practices

### Infrastructure
- Use remote state backend
- Enable state locking
- Regular drift detection
- Resource tagging

### Content
- Separate infrastructure and content
- Automated deployment
- Version control
- Backup procedures

### Security
- Least privilege access
- Regular security scans
- Cost monitoring
- Audit logging
