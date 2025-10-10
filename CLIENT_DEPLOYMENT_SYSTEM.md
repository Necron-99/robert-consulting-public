# Client Deployment System

## Overview

The Client Deployment System provides a comprehensive solution for managing content deployments from client repositories to AWS infrastructure managed in this repository. This system enables:

- **Automated content deployment** from client GitHub repositories
- **Infrastructure management** via Terraform
- **Web-based admin interface** for deployment management
- **Scheduled deployments** and manual triggers
- **Multi-client support** with isolated configurations

## Architecture

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Client Repository │    │  Robert Consulting  │    │   AWS Infrastructure│
│                     │    │     Repository      │    │                     │
│  ┌───────────────┐  │    │  ┌───────────────┐  │    │  ┌───────────────┐  │
│  │   Content     │  │    │  │   Deployment  │  │    │  │   S3 Bucket   │  │
│  │   (HTML/CSS/  │  │───▶│  │   Scripts     │  │───▶│  │   CloudFront  │  │
│  │    JS/Assets) │  │    │  │   Admin UI    │  │    │  │   Route 53    │  │
│  └───────────────┘  │    │  └───────────────┘  │    │  └───────────────┘  │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## Components

### 1. Deployment Scripts

#### `scripts/deploy-client-content.sh`
Main deployment script that:
- Clones client repository
- Syncs content to S3
- Invalidates CloudFront cache
- Verifies deployment

#### `scripts/setup-client-deployment.sh`
Setup script for new clients that:
- Creates client configuration
- Generates Terraform files
- Sets up deployment scripts
- Creates documentation

### 2. Admin Interface

#### `admin/client-deployment.html`
Web-based interface providing:
- Client configuration management
- One-click deployments
- Infrastructure status monitoring
- Deployment logs and history

#### `admin/index.html`
Main admin dashboard with:
- Quick access to client deployments
- Infrastructure management links
- Documentation access

### 3. GitHub Actions

#### `.github/workflows/deploy-client-content.yml`
Automated deployment workflow supporting:
- Manual deployments via workflow dispatch
- Scheduled deployments for all clients
- Parameter validation and error handling

### 4. Client Configuration

Each client has a dedicated directory structure:
```
clients/
└── {client_name}/
    ├── config.json          # Client configuration
    ├── main.tf             # Terraform infrastructure
    ├── deploy.sh           # Client-specific deployment script
    └── README.md           # Client documentation
```

## Setup Instructions

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/username/robert-consulting.net.git
cd robert-consulting.net

# Configure AWS credentials
aws configure

# Verify AWS access
aws sts get-caller-identity
```

### 2. Add New Client

```bash
# Run setup script
./scripts/setup-client-deployment.sh baileylessons username/baileylessons.com baileylessons.com

# Navigate to client directory
cd clients/baileylessons

# Initialize and deploy infrastructure
terraform init
terraform plan
terraform apply

# Update configuration with CloudFront distribution ID
terraform output cloudfront_distribution_id
# Update config.json with the output

# Deploy content
./deploy.sh
```

### 3. Admin Interface Access

Access the admin interface at: `https://your-domain.com/admin/`

## Usage

### Manual Deployment

#### Via Admin Interface
1. Navigate to `/admin/client-deployment.html`
2. Configure client settings if needed
3. Click "Deploy Now" button
4. Monitor deployment logs

#### Via Command Line
```bash
# Deploy specific client
./scripts/deploy-client-content.sh baileylessons username/baileylessons.com baileylessons-website E1TD9DYEU1B2AJ

# Deploy from client directory
cd clients/baileylessons
./deploy.sh
```

#### Via GitHub Actions
1. Go to Actions tab in GitHub
2. Select "Deploy Client Content" workflow
3. Click "Run workflow"
4. Fill in required parameters
5. Click "Run workflow"

### Scheduled Deployments

The system automatically runs daily at 6 AM UTC to check for updates in all configured client repositories.

### Configuration Management

#### Client Configuration (`config.json`)
```json
{
  "client_name": "baileylessons",
  "client_repo": "username/baileylessons.com",
  "domain": "baileylessons.com",
  "s3_bucket": "baileylessons-website-20250101-abc123",
  "cloudfront_distribution_id": "E1TD9DYEU1B2AJ",
  "region": "us-east-1",
  "created_at": "2025-01-01T00:00:00Z",
  "status": "active"
}
```

#### Environment Variables
```bash
# Required for GitHub Actions
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Optional
WAIT_FOR_INVALIDATION=true  # Wait for CloudFront invalidation
```

## Client Repository Requirements

Client repositories should have one of these directory structures:

```
# Option 1: content/ directory
content/
├── index.html
├── styles.css
├── script.js
└── assets/

# Option 2: website/ directory
website/
├── index.html
├── styles.css
├── script.js
└── assets/

# Option 3: public/ directory
public/
├── index.html
├── styles.css
├── script.js
└── assets/
```

## Security

### AWS Permissions
The deployment system requires these AWS permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### GitHub Secrets
Required secrets in the repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Monitoring and Troubleshooting

### Deployment Logs
- Admin interface provides real-time deployment logs
- GitHub Actions provides detailed workflow logs
- Command-line scripts provide colored output

### Common Issues

#### 1. Repository Access
```bash
# Check if repository is accessible
git clone https://github.com/username/repo.git
```

#### 2. AWS Permissions
```bash
# Verify AWS access
aws sts get-caller-identity
aws s3 ls s3://bucket-name
```

#### 3. CloudFront Invalidation
```bash
# Check invalidation status
aws cloudfront get-invalidation --distribution-id DISTRIBUTION_ID --id INVALIDATION_ID
```

### Health Checks

#### Infrastructure Status
```bash
# Check S3 bucket
aws s3 ls s3://bucket-name

# Check CloudFront distribution
aws cloudfront get-distribution --id DISTRIBUTION_ID

# Check deployment status
./scripts/deploy-client-content.sh --validate CLIENT_NAME REPO BUCKET DISTRIBUTION_ID
```

## Best Practices

### 1. Repository Management
- Keep client repositories separate from infrastructure
- Use semantic versioning for content releases
- Implement proper .gitignore files

### 2. Deployment Strategy
- Test deployments in staging environment first
- Use feature branches for content development
- Implement rollback procedures

### 3. Monitoring
- Set up CloudWatch alarms for infrastructure
- Monitor deployment success rates
- Track content update frequencies

### 4. Security
- Use least-privilege AWS IAM policies
- Rotate access keys regularly
- Implement proper secret management

## API Reference

### Deployment Script Parameters
```bash
./scripts/deploy-client-content.sh <client_name> <client_repo> <bucket_name> <cloudfront_distribution_id>
```

### Environment Variables
- `WAIT_FOR_INVALIDATION`: Wait for CloudFront invalidation (true/false)
- `AWS_REGION`: AWS region (default: us-east-1)

### Configuration Schema
```json
{
  "client_name": "string",
  "client_repo": "string",
  "domain": "string",
  "s3_bucket": "string",
  "cloudfront_distribution_id": "string",
  "region": "string",
  "created_at": "ISO8601 timestamp",
  "status": "pending_setup|active|inactive"
}
```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review deployment logs
3. Contact Robert Consulting support

## Changelog

### Version 1.0.0 (2025-01-01)
- Initial release
- Basic deployment functionality
- Admin interface
- GitHub Actions integration
- Multi-client support
