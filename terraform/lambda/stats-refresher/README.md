# Dashboard Stats Refresher Lambda

This Lambda function refreshes dashboard statistics with live data from GitHub, AWS, and health checks.

## Features

- **GitHub Statistics**: Commits (7d/30d) with categorization (feature, bug, improvement, security, infrastructure, documentation)
- **AWS Cost Data**: Real-time monthly costs by service (S3, CloudFront, Lambda, Route53, SES, WAF, CloudWatch)
- **Traffic Metrics**: CloudFront requests/bandwidth, S3 storage/objects, Route53 queries
- **Health Checks**: Site response time and status
- **CloudFront Invalidation**: Automatic cache clearing after stats update

## Setup Instructions

### 1. Deploy Infrastructure

```bash
# Apply Terraform configuration
cd terraform
terraform plan
terraform apply
```

### 2. Set GitHub Token

```bash
# Update the GitHub token in Secrets Manager
aws secretsmanager update-secret \
  --secret-id github-token-dashboard-stats \
  --secret-string '{"token":"your-github-token-here"}'
```

### 3. Deploy Lambda Function

```bash
# Build and deploy the Lambda package
cd lambda/stats-refresher
npm install --production
cd ../..
terraform apply
```

## Usage

### Automatic (Recommended)
The Lambda is automatically invoked after each production deployment via GitHub Actions.

### Manual Refresh
```bash
# Invoke via AWS CLI
aws lambda invoke \
  --function-name dashboard-stats-refresher \
  --payload '{}' \
  response.json

# Or via API Gateway
curl -X POST https://your-api-gateway-url/refresh-stats
```

## Data Schema

The function generates `/data/dashboard-stats.json` with this structure:

```json
{
  "generatedAt": "2025-01-14T19:30:00Z",
  "github": {
    "totalCommits7d": 198,
    "totalCommits30d": 418,
    "commitCategories": {
      "feature": 45,
      "bug": 23,
      "improvement": 67,
      "security": 12,
      "infrastructure": 34,
      "documentation": 17
    }
  },
  "aws": {
    "monthlyCostTotal": 6.82,
    "services": {
      "s3": 0.05,
      "cloudfront": 2.10,
      "lambda": 0.15,
      "route53": 0.50,
      "ses": 0.10,
      "waf": 0.20,
      "cloudwatch": 0.10,
      "other": 3.62
    }
  },
  "traffic": {
    "cloudfront": {
      "requests24h": 1234,
      "bandwidth24h": "2.5GB"
    },
    "s3": {
      "objects": 87,
      "storageGB": 0.001
    }
  },
  "health": {
    "site": {
      "status": "healthy",
      "responseMs": 120
    },
    "route53": {
      "queries24h": 567
    }
  }
}
```

## Cost Estimate

- **Lambda**: ~$0.01/month (deploy-only triggers)
- **CloudFront Invalidations**: ~$0.40/month (1 path per deploy)
- **Total**: Under $0.50/month

## Monitoring

- **CloudWatch Logs**: `/aws/lambda/dashboard-stats-refresher`
- **Log Retention**: 14 days
- **Error Handling**: Graceful fallbacks for partial failures

## Security

- **IAM Role**: Least-privilege access to required AWS services
- **Secrets Manager**: GitHub token stored securely
- **No PII**: Only aggregated statistics, no personal data
