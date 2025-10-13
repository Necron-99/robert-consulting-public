# Robert Consulting Infrastructure Framework

This repository contains the skeleton client template for creating new client infrastructure using the Robert Consulting infrastructure framework.

## 🎯 Overview

This framework provides a complete, production-ready serverless infrastructure setup that can be customized for any client. It includes built-in cost optimization, monitoring, and security features.

## 📁 Repository Structure

```
robert-consulting.net/
├── README.md                           # This file
├── .gitignore                         # Git ignore rules
├── .eslintrc.json                     # ESLint configuration
├── .stylelintrc.json                  # Stylelint configuration
├── package.json                       # Node.js dependencies
├── docs/                              # 📚 All documentation
│   ├── README.md                      # Documentation index
│   ├── guides/                        # Setup and configuration guides
│   ├── reports/                       # Analysis and summary reports
│   ├── deployment/                    # Deployment documentation
│   ├── security/                      # Security documentation
│   └── infrastructure/                # Infrastructure documentation
├── scripts/                           # 🔧 Automation scripts
│   ├── README.md                      # Scripts index
│   ├── deployment/                    # Deployment scripts
│   ├── security/                      # Security scripts
│   ├── maintenance/                   # Maintenance scripts
│   └── utilities/                     # Utility scripts
├── config/                            # ⚙️ Configuration files
│   ├── README.md                      # Configuration index
│   ├── terraform/                     # Terraform configurations
│   ├── aws/                          # AWS configurations
│   └── github/                       # GitHub configurations
├── website/                           # 🌐 Main website content
│   ├── index.html                     # Homepage
│   ├── dashboard.html                 # Dashboard page
│   ├── learning.html                  # Learning page
│   ├── css/                          # Stylesheets
│   ├── js/                           # JavaScript files
│   └── api/                          # API endpoints
├── admin/                             # 🔐 Admin site
│   ├── index.html                     # Admin dashboard
│   ├── baileylessons/                 # Bailey Lessons admin
│   └── js/                           # Admin JavaScript
├── terraform/                         # 🏗️ Infrastructure as Code
│   ├── infrastructure.tf              # Main infrastructure
│   ├── staging-environment.tf         # Staging environment
│   ├── admin-site.tf                  # Admin site infrastructure
│   └── modules/                       # Reusable modules
├── .github/                           # 🤖 GitHub Actions
│   ├── workflows/                     # CI/CD workflows
│   └── environments/                  # Environment configurations
├── skeleton-client/                   # 📋 Client template
├── client-template/                   # 📋 Client template
├── client-content-template/           # 📋 Content template
└── lambda/                            # ⚡ Lambda functions
    ├── staging-token-generator/       # Staging access control
    └── staging-url-generator/         # URL generation
```

## 💰 Cost Analysis

### Serverless Configuration
- **Monthly Cost**: $0.96-$20.91
- **Annual Cost**: $11.52-$250.92
- **Savings**: 94-99% reduction from traditional infrastructure

### Cost Breakdown
| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| **Lambda Functions** | $0.00-$5.00 | Pay-per-request |
| **API Gateway** | $0.00-$3.50 | Pay-per-request |
| **DynamoDB** | $0.00-$2.00 | Pay-per-request |
| **S3 Storage** | $0.46 | 20GB storage |
| **CloudFront** | $0.00-$8.50 | Global CDN |
| **Route53** | $0.50 | DNS management |
| **Total** | $0.96-$20.91 | **94-99% savings** |

## 🚀 Quick Start

### 1. Create New Client

#### Using the Client Creation Script
```bash
cd skeleton-client
./scripts/create-client.sh -c your-client-name -e production
```

#### Manual Setup
```bash
# Copy the template configuration
cp skeleton-client/terraform.tfvars.example your-client/terraform.tfvars

# Customize the configuration
nano your-client/terraform.tfvars

# Deploy the infrastructure
cd your-client
terraform init
terraform plan
terraform apply
```

### 2. Customize Client Configuration

#### Edit terraform.tfvars
```hcl
# Client Information
client_name = "your-client-name"
project_name = "your-project-name"
environment = "production"

# Domain Configuration
domain_name = "your-client.com"
certificate_domain = "your-client.com"

# Budget Configuration
monthly_budget_limit = 100
budget_alert_emails = [
  "admin@your-client.com",
  "finance@your-client.com"
]
```

### 3. Deploy Client Infrastructure

#### Automated Deployment
```bash
cd clients/your-client-name
./deploy.sh
```

#### Manual Deployment
```bash
cd clients/your-client-name
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## 🔧 Configuration

### Client-Specific Settings

#### Domain Configuration
- **Custom Domain**: your-client.com
- **SSL Certificate**: ACM certificate
- **WWW Redirect**: Enabled
- **Route53**: Clean DNS management

#### Lambda Functions
- **API Function**: Handle API requests
- **Auth Function**: Handle authentication
- **Admin Function**: Handle admin operations
- **Runtime**: Node.js 18.x
- **Memory**: 128 MB
- **Timeout**: 30 seconds

#### API Gateway
- **REST API**: HTTP API endpoints
- **Throttling**: 1000 requests/second
- **Caching**: Enabled for performance
- **CORS**: Configured for web access

#### DynamoDB Tables
- **Users Table**: User management
- **Content Table**: Content management
- **Analytics Table**: Analytics tracking
- **Billing**: Pay-per-request
- **Encryption**: Enabled at rest

#### S3 Storage
- **Static Bucket**: Website hosting
- **Uploads Bucket**: User uploads
- **Backups Bucket**: Backup storage
- **Versioning**: Enabled
- **CORS**: Configured

#### CloudFront CDN
- **Global Distribution**: Edge locations worldwide
- **Caching**: Optimized for static and dynamic content
- **Compression**: Enabled
- **HTTP/2**: Enabled
- **Custom Domain**: your-client.com

## 📊 Performance Characteristics

### Expected Performance
- **Concurrent Users**: 1000+ (serverless auto-scaling)
- **Response Time**: 200ms (CloudFront + Lambda)
- **Availability**: 99.9% (AWS managed services)
- **Global Reach**: CloudFront edge locations
- **Auto Scaling**: Automatic based on demand

### Benefits
- **High Availability**: AWS managed services
- **Global CDN**: CloudFront edge locations
- **Auto Scaling**: Automatic based on demand
- **Cost Effective**: Pay-per-request pricing
- **No Maintenance**: Fully managed services

## 💡 Cost Optimization Features

### Automated Optimizations
- **Pay-Per-Request**: Only pay for actual usage
- **Auto Scaling**: Automatic based on demand
- **CloudFront Caching**: Reduce origin load
- **S3 Lifecycle**: Automatic transitions
- **Route53**: Minimal DNS records

### Cost Monitoring
- **Budget Alerts**: 80% and 100% threshold notifications
- **Daily Reports**: Automated cost analysis
- **Resource Cleanup**: Automatic cleanup of unused resources

## 📋 Monitoring and Alerting

### CloudWatch Dashboards
- **Lambda Metrics**: Function invocations, errors, duration
- **API Gateway Metrics**: Request count, latency, error rates
- **DynamoDB Metrics**: Read/write capacity, throttled requests
- **CloudFront Metrics**: Cache hit ratio, data transfer
- **S3 Metrics**: Bucket size, object count
- **Cost Monitoring**: Estimated charges and budget tracking

### Alert Configuration
- **Cost Alerts**: Budget threshold notifications
- **Performance Alerts**: Lambda errors, API Gateway errors
- **Database Alerts**: DynamoDB throttled requests
- **Application Alerts**: Error rates, response times
- **Infrastructure Alerts**: Service health status

## 🛠️ Maintenance

### Regular Tasks

#### Daily
- Check CloudWatch alarms
- Review cost reports
- Monitor application health

#### Weekly
- Review performance metrics
- Check backup status
- Update security patches

#### Monthly
- Comprehensive cost review
- Infrastructure optimization
- Documentation updates

### Backup Procedures

#### Automated Backups
```bash
# DynamoDB point-in-time recovery is enabled
# S3 cross-region replication can be configured
# Lambda code is version controlled
```

#### Manual Backups
- **DynamoDB**: Point-in-time recovery enabled
- **S3 Bucket Sync**: Regular bucket synchronization
- **Terraform State**: State file backups
- **Configuration Files**: Client configuration backups

### Cleanup Procedures

#### Safe Cleanup
```bash
# Create backup first
./scripts/backup-client.sh -c your-client-name

# Then cleanup
./scripts/cleanup-client.sh -c your-client-name
```

## 🔍 Troubleshooting

### Common Issues

#### Deployment Failures
1. **Check AWS Credentials**
   ```bash
   aws sts get-caller-identity
   ```

2. **Verify Terraform Configuration**
   ```bash
   terraform validate
   terraform plan
   ```

3. **Review Error Logs**
   ```bash
   aws logs describe-log-groups
   aws logs get-log-events --log-group-name /aws/lambda/your-client-production-api
   ```

#### Performance Issues
1. **Check Lambda Functions**
   ```bash
   aws lambda list-functions --query "Functions[?contains(FunctionName, 'your-client')]"
   ```

2. **Review API Gateway Metrics**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ApiGateway \
     --metric-name Count \
     --dimensions Name=ApiName,Value=your-client-api
   ```

3. **Check DynamoDB Metrics**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ConsumedReadCapacityUnits \
     --dimensions Name=TableName,Value=your-client-production-users
   ```

#### Cost Issues
1. **Review Cost Reports**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY \
     --metrics BlendedCost
   ```

2. **Check Resource Utilization**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Lambda \
     --metric-name Invocations \
     --dimensions Name=FunctionName,Value=your-client-production-api
   ```

## 📞 Support

### Getting Help

1. **Check Documentation**
   - Review client-specific documentation
   - Check troubleshooting guides
   - Review AWS documentation

2. **Contact Support**
   - Technical support: support@robert-consulting.net
   - Emergency support: +1-555-0123
   - GitHub issues: https://github.com/robert-consulting/skeleton-client/issues

### Escalation Process

1. **Level 1**: Self-service documentation
2. **Level 2**: Technical support email
3. **Level 3**: Engineering team escalation
4. **Level 4**: Emergency phone support

## 🔄 Updates and Changes

### Making Changes

1. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make changes**
   - Update configuration files
   - Modify infrastructure code
   - Test changes locally

3. **Deploy changes**
   ```bash
   terraform plan
   terraform apply
   ```

4. **Create pull request**
   - Review changes
   - Get approval
   - Merge to main branch

### Version Control

- Infrastructure changes are tracked in Git
- Terraform state is stored in S3
- All changes are logged and auditable

## 📈 Scaling

### Horizontal Scaling
- Lambda functions automatically scale based on demand
- API Gateway handles load balancing
- DynamoDB scales automatically
- CloudFront distributes traffic globally

### Vertical Scaling
- Update Lambda memory allocation
- Optimize DynamoDB queries
- Adjust API Gateway throttling
- Optimize CloudFront caching

## 🔒 Security

### Network Security
- VPC with private subnets for databases
- Security groups with least-privilege access
- Network ACLs for additional protection

### Data Security
- DynamoDB encryption at rest and in transit
- S3 bucket encryption
- Secrets stored in AWS Secrets Manager
- IAM roles with minimal permissions

### Application Security
- Lambda function security scanning
- Vulnerability assessments
- Automated security updates

## 📚 Additional Resources

### Documentation
- **Skeleton Template**: [skeleton-client/README.md](skeleton-client/README.md)
- **Client Template**: [skeleton-client/terraform.tfvars.example](skeleton-client/terraform.tfvars.example)
- **Deployment Guide**: [skeleton-client/scripts/README.md](skeleton-client/scripts/README.md)
- **Troubleshooting Guide**: [skeleton-client/scripts/TROUBLESHOOTING.md](skeleton-client/scripts/TROUBLESHOOTING.md)

### Tools and Scripts
- **Client Creation**: [skeleton-client/scripts/create-client.sh](skeleton-client/scripts/create-client.sh)
- **Client Deployment**: [skeleton-client/scripts/deploy-client.sh](skeleton-client/scripts/deploy-client.sh)
- **Client Cleanup**: [skeleton-client/scripts/cleanup-client.sh](skeleton-client/scripts/cleanup-client.sh)
- **Client Backup**: [skeleton-client/scripts/backup-client.sh](skeleton-client/scripts/backup-client.sh)

### Support
- **Technical Support**: support@robert-consulting.net
- **Emergency Support**: +1-555-0123
- **Documentation**: https://docs.robert-consulting.net
- **GitHub Issues**: https://github.com/robert-consulting/skeleton-client/issues

---

This framework provides a solid foundation for client infrastructure, with built-in cost optimization, high availability, and comprehensive monitoring. The serverless architecture makes it easy to scale while maintaining cost efficiency.