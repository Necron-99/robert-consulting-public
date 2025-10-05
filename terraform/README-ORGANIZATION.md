# AWS Organizations Setup for Robert Consulting

This directory contains the infrastructure setup for Robert Consulting's multi-client AWS organization structure.

## Overview

The organization structure includes:
- **Management Account**: Robert Consulting's main account for managing all client accounts
- **Client Accounts**: Separate AWS accounts for each client (starting with baileylessons.com)
- **Shared Services**: Common infrastructure components
- **Cross-Account Access**: Secure access patterns for management

## Structure

```
Robert Consulting Organization
├── Management Account (robert-consulting.net)
│   ├── Organizations Management
│   ├── Billing & Cost Management
│   ├── Security & Compliance
│   └── Cross-Account Access Roles
├── Client Accounts OU
│   └── baileylessons.com Account
│       ├── S3 Website Hosting
│       ├── CloudFront CDN
│       ├── Route 53 DNS
│       ├── WAF Protection
│       └── CloudWatch Monitoring
└── Shared Services OU
    ├── Common Security Policies
    ├── Tag Policies
    └── Service Control Policies
```

## Files

### Core Organization Files
- `organizations.tf` - Main organization structure and policies
- `setup-organization.sh` - Automated setup script
- `README-ORGANIZATION.md` - This documentation

### Client Infrastructure
- `modules/client-infrastructure/` - Reusable module for client infrastructure
- `baileylessons.tf` - Specific configuration for Bailey Lessons client

## Prerequisites

1. **AWS CLI** installed and configured
2. **Terraform** >= 1.0 installed
3. **AWS Organizations** permissions in the management account
4. **Billing access** for cost management
5. **Domain ownership** for client domains

## Setup Instructions

### 1. Initial Organization Setup

```bash
# Navigate to terraform directory
cd terraform

# Make setup script executable
chmod +x setup-organization.sh

# Run the setup script
./setup-organization.sh
```

### 2. Manual Setup (Alternative)

```bash
# Initialize Terraform
terraform init

# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

### 3. Client Account Setup

After the organization is created, set up individual client accounts:

```bash
# For Bailey Lessons
cd clients/baileylessons
terraform init
terraform plan
terraform apply
```

## Security Features

### Service Control Policies (SCPs)
- **Root User Protection**: Prevents dangerous root user actions
- **MFA Enforcement**: Requires MFA for all actions
- **Internet Gateway Restrictions**: Prevents direct internet access

### Tag Policies
- **Consistent Tagging**: Enforces standard tags across all resources
- **Cost Allocation**: Enables cost tracking by client
- **Compliance**: Ensures regulatory compliance

### Cross-Account Access
- **Assumed Roles**: Secure cross-account access patterns
- **External ID**: Additional security for role assumption
- **Least Privilege**: Minimal required permissions

## Client Infrastructure Features

### Website Hosting
- **S3 Static Website**: Cost-effective static hosting
- **CloudFront CDN**: Global content delivery
- **Route 53 DNS**: Reliable domain management
- **SSL/TLS**: Automatic HTTPS with ACM certificates

### Security
- **AWS WAF**: Web application firewall
- **Rate Limiting**: Protection against abuse
- **SQL Injection Protection**: Database security
- **XSS Protection**: Cross-site scripting prevention

### Monitoring
- **CloudWatch Dashboards**: Real-time metrics
- **SNS Alerts**: Automated notifications
- **Cost Monitoring**: Budget alerts and tracking
- **Performance Metrics**: Core Web Vitals tracking

## Cost Management

### Billing Structure
- **Consolidated Billing**: All accounts under one bill
- **Cost Allocation Tags**: Track costs by client
- **Budget Alerts**: Prevent cost overruns
- **Reserved Instances**: Optimize long-term costs

### Cost Optimization
- **S3 Intelligent Tiering**: Automatic cost optimization
- **CloudFront Caching**: Reduce origin requests
- **Lambda Serverless**: Pay-per-use compute
- **Resource Tagging**: Identify unused resources

## Client Onboarding Process

### 1. Account Creation
- Create new AWS account via Organizations
- Apply security policies and tags
- Set up cross-account access

### 2. Infrastructure Deployment
- Deploy client infrastructure module
- Configure domain and DNS
- Set up monitoring and alerts

### 3. Security Configuration
- Apply WAF rules
- Configure SSL certificates
- Set up access controls

### 4. Monitoring Setup
- Configure CloudWatch dashboards
- Set up SNS notifications
- Create cost budgets

## Management Access

### Cross-Account Roles
Each client account has a cross-account role for management:

```bash
# Assume role for client management
aws sts assume-role \
  --role-arn "arn:aws:iam::CLIENT_ACCOUNT_ID:role/RobertConsultingCrossAccountRole-CLIENT_NAME" \
  --role-session-name "RobertConsulting-Session" \
  --external-id "robert-consulting-CLIENT_NAME"
```

### Terraform State Management
- **S3 Backend**: Remote state storage
- **DynamoDB Locking**: Prevent concurrent modifications
- **State Encryption**: Secure state files

## Best Practices

### Security
1. **Least Privilege**: Minimal required permissions
2. **MFA Enforcement**: Multi-factor authentication required
3. **Regular Audits**: Periodic access reviews
4. **Encryption**: Data encryption at rest and in transit

### Cost Management
1. **Resource Tagging**: Consistent tagging strategy
2. **Budget Alerts**: Proactive cost monitoring
3. **Regular Reviews**: Monthly cost optimization
4. **Reserved Capacity**: Long-term cost savings

### Operations
1. **Infrastructure as Code**: All resources in Terraform
2. **Version Control**: Git-based change management
3. **Automated Deployment**: CI/CD pipelines
4. **Monitoring**: Comprehensive observability

## Troubleshooting

### Common Issues

#### Organization Creation Fails
- Check AWS Organizations permissions
- Verify billing account access
- Ensure account is not already in an organization

#### Client Account Access Issues
- Verify cross-account role configuration
- Check external ID matches
- Ensure proper IAM permissions

#### Terraform State Issues
- Verify S3 backend configuration
- Check DynamoDB table permissions
- Ensure state file encryption

### Support Contacts
- **Technical Issues**: Robert Consulting DevOps Team
- **Billing Questions**: AWS Support
- **Security Concerns**: AWS Security Team

## Next Steps

1. **Deploy Organization**: Run the setup script
2. **Configure DNS**: Set up domain name servers
3. **Client Onboarding**: Deploy client infrastructure
4. **Monitoring Setup**: Configure alerts and dashboards
5. **Documentation**: Update client-specific documentation

## Resources

- [AWS Organizations Documentation](https://docs.aws.amazon.com/organizations/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/security/security-resources/)
