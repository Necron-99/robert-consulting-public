# Deployment Guide

## Infrastructure Deployment

### Prerequisites
- AWS CLI configured with management account credentials
- Terraform >= 1.0
- Access to client AWS account via `RobertClientDeploymentRole`

### Initial Setup
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with client details

terraform init
terraform plan
terraform apply
```

### Adopting Existing Resources
If the client has existing CloudFront, Route53, or ACM resources:

1. **Set existing resource IDs in terraform.tfvars:**
```hcl
existing_cloudfront_distribution_id = "E23X7BS3VXFFFZ"
existing_route53_zone_id            = "Z01009052GCOJI1M2TTF7"
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:...:certificate/..."
```

2. **Import existing Route53 records:**
```bash
terraform import 'module.infrastructure.aws_route53_record.website[0]' ZONEID_example.com_A
terraform import 'module.infrastructure.aws_route53_record.additional[0]' ZONEID_www.example.com_A
```

3. **Apply changes:**
```bash
terraform plan
terraform apply
```

## Content Deployment

### Manual Deployment
```bash
cd content
./deploy.sh
```

### Automated Deployment
Content is automatically deployed via GitHub Actions when:
- Changes are pushed to the `content/` directory
- Workflow is manually triggered

### Content Structure
```
content/
├── website/
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── assets/
└── deploy.sh
```

## CI/CD Configuration

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: Management account credentials
- `AWS_SECRET_ACCESS_KEY`: Management account credentials
- `CLIENT_ACCOUNT_ID`: Target client AWS account ID
- `MANAGEMENT_ACCOUNT_ID`: Your management account ID
- `CLIENT_NAME`: Client name (for SSM parameters)
- `CLIENT_DOMAIN`: Client domain name

### Workflows
- **Infrastructure**: Deploys on changes to `infrastructure/` directory
- **Content**: Deploys on changes to `content/` directory
- **Drift Check**: Runs daily to detect infrastructure drift

## Monitoring

### Cost Monitoring
- Budget alerts configured for cost thresholds
- CloudWatch dashboards for cost tracking
- SNS notifications for budget alerts

### Performance Monitoring
- CloudFront metrics and alarms
- S3 access logs and metrics
- Real-time performance dashboards

### Security Monitoring
- WAF logs and metrics
- Security scanning and vulnerability detection
- Access logging and audit trails

## Troubleshooting

### Common Issues

#### Infrastructure
- **State lock conflicts**: Check DynamoDB lock table
- **Permission errors**: Verify IAM role assumptions
- **Resource conflicts**: Check for existing resources

#### Content
- **Deployment failures**: Check S3 permissions
- **Cache issues**: Invalidate CloudFront manually
- **DNS propagation**: Allow time for DNS changes

#### CI/CD
- **Workflow failures**: Check GitHub secrets
- **Permission errors**: Verify AWS credentials
- **SSM parameter errors**: Ensure infrastructure is deployed

### Recovery Procedures

#### State Corruption
```bash
# Restore from S3 versioning
aws s3 cp s3://robert-consulting-terraform-state/clients/[CLIENT_NAME]/terraform.tfstate.backup terraform.tfstate
```

#### Resource Drift
```bash
# Import existing resources
terraform import aws_s3_bucket.example bucket-name
terraform import aws_cloudfront_distribution.example distribution-id
```

#### Deployment Failures
```bash
# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/[CLIENT_NAME]"
```

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
