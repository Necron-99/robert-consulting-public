# [CLIENT_NAME] Infrastructure

This repository manages the infrastructure and content for [CLIENT_NAME].

## Repository Structure

```
├── infrastructure/     # Terraform infrastructure code
├── content/          # Website content and assets
├── .github/workflows/ # CI/CD automation
└── docs/            # Documentation
```

## Quick Start

### Prerequisites
- AWS CLI configured with management account credentials
- Terraform >= 1.0
- GitHub repository with required secrets

### Initial Setup
```bash
# 1. Configure client settings
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with client details

# 2. Initialize Terraform
terraform init

# 3. Plan and apply infrastructure
terraform plan
terraform apply
```

### Content Deployment
```bash
# Deploy website content
cd content
./deploy.sh
```

## Configuration

### Client Settings (terraform.tfvars)
```hcl
client_name        = "[CLIENT_NAME]"
client_domain      = "[CLIENT_DOMAIN]"
aws_region         = "us-east-1"
environment        = "production"

# Additional domains
additional_domains = ["www.[CLIENT_DOMAIN]", "app.[CLIENT_DOMAIN]"]

# Existing resources (if adopting)
existing_cloudfront_distribution_id = "E..."
existing_route53_zone_id            = "Z..."
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:...:certificate/..."
```

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: Management account credentials
- `AWS_SECRET_ACCESS_KEY`: Management account credentials  
- `CLIENT_ACCOUNT_ID`: Target client AWS account ID
- `MANAGEMENT_ACCOUNT_ID`: Your management account ID

## Deployment

### Infrastructure
- **Manual**: `terraform apply` in infrastructure/ directory
- **Automated**: GitHub Actions on infrastructure changes

### Content
- **Manual**: Run `./content/deploy.sh`
- **Automated**: GitHub Actions on content changes

## Monitoring

- **Cost**: Budget alerts and cost dashboards
- **Performance**: CloudWatch metrics and alarms
- **Security**: WAF rules and vulnerability scanning
- **Drift**: Automated infrastructure drift detection

## Support

- **Documentation**: See docs/ directory
- **Issues**: Create GitHub issues for problems
- **Contact**: [YOUR_CONTACT_INFO]

## License

[LICENSE_INFO]
