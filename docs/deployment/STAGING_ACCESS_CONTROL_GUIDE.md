# Staging Access Control Guide

## Overview

This guide explains the new staging access control system that replaces IP whitelisting with CloudFront signed URLs, providing secure access to the staging environment without the limitations of IP-based restrictions.

## Problem with IP Whitelisting

- **GitHub Actions IPs**: Constantly changing, requiring frequent updates
- **Personal IP Changes**: Dynamic IPs, VPN usage, mobile connections
- **Testing Limitations**: Automated tests can't access staging
- **Maintenance Overhead**: Manual IP management and updates

## New Solution: CloudFront Signed URLs

### How It Works

1. **CloudFront Key Pair**: Uses AWS CloudFront key pairs for URL signing
2. **Signed URLs**: Generate time-limited, secure URLs for staging access
3. **API Gateway**: RESTful API for generating access URLs
4. **Lambda Function**: Serverless function to handle URL generation
5. **Access Page**: Web interface for easy URL generation

### Benefits

- ✅ **No IP Restrictions**: Works from anywhere
- ✅ **Time-Limited Access**: URLs expire automatically
- ✅ **Secure**: Cryptographically signed URLs
- ✅ **Automated**: Works with CI/CD pipelines
- ✅ **User-Friendly**: Simple web interface
- ✅ **Auditable**: Track who generates URLs and when

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User/CI/CD    │───▶│   API Gateway    │───▶│  Lambda Function│
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  CloudFront      │    │  CloudFront     │
                       │  Key Pair        │    │  Distribution   │
                       └──────────────────┘    └─────────────────┘
```

## Implementation

### 1. CloudFront Configuration

```terraform
# CloudFront Key Pair for Signed URLs
resource "aws_cloudfront_public_key" "staging_access_key" {
  comment     = "Staging environment access key"
  encoded_key = file("${path.module}/staging-access-key.pem")
  name        = "staging-access-key"
}

# CloudFront Key Group
resource "aws_cloudfront_key_group" "staging_access_group" {
  comment = "Staging environment access group"
  items   = [aws_cloudfront_public_key.staging_access_key.id]
  name    = "staging-access-group"
}
```

### 2. Lambda Function

The Lambda function generates signed URLs using CloudFront's signing algorithm:

```python
def generate_signed_url(distribution_id, key_pair_id, private_key, url, expiration_hours=24):
    # Calculate expiration time
    expiration = int(time.time()) + (expiration_hours * 3600)
    
    # Create policy and sign it
    policy = create_policy(url, expiration)
    signed_url = sign_policy(policy, private_key)
    
    return signed_url
```

### 3. API Gateway

RESTful API endpoint for generating URLs:

```
POST /staging-url
{
  "path": "/dashboard.html",
  "expiration_hours": 24
}
```

### 4. Access Page

Simple web interface at `/staging-access.html` for generating URLs.

## Usage

### For Manual Testing

1. Visit the staging access page
2. Enter the path you want to access
3. Select expiration duration
4. Click "Generate Access URL"
5. Use the generated URL to access staging

### For Automated Testing

```bash
# Generate signed URL via API
curl -X POST https://api.robertconsulting.net/staging-url \
  -H "Content-Type: application/json" \
  -d '{"path": "/dashboard.html", "expiration_hours": 1}'

# Use the returned signed URL for testing
curl "$SIGNED_URL"
```

### For CI/CD Pipelines

The comprehensive workflow automatically generates signed URLs for testing:

```yaml
- name: 🔍 OWASP ZAP Security Scan
  run: |
    # Generate signed URL for staging
    SIGNED_URL=$(curl -s -X POST $API_URL/staging-url \
      -H "Content-Type: application/json" \
      -d '{"path": "/", "expiration_hours": 1}' | jq -r '.signed_url')
    
    # Run security scan
    ./zap.sh quick-scan "$SIGNED_URL"
```

## Security Considerations

### Key Management

- **Private Key**: Store securely in AWS Secrets Manager
- **Key Rotation**: Regular rotation of CloudFront key pairs
- **Access Logging**: Log all URL generation requests

### URL Security

- **Time-Limited**: URLs expire automatically
- **Path-Specific**: URLs are tied to specific paths
- **Cryptographically Signed**: Cannot be forged or modified

### Access Control

- **API Authentication**: Consider adding API key authentication
- **Rate Limiting**: Limit URL generation requests
- **Audit Trail**: Log all access attempts

## Deployment

### 1. Deploy Terraform

```bash
# Apply staging access control
terraform apply -target=aws_cloudfront_public_key.staging_access_key
terraform apply -target=aws_cloudfront_key_group.staging_access_group
terraform apply -target=aws_lambda_function.staging_url_generator
terraform apply -target=aws_api_gateway_rest_api.staging_access_api
```

### 2. Package and Deploy Lambda

```bash
# Package Lambda function
./scripts/package-lambda.sh

# Deploy Lambda function
aws lambda update-function-code \
  --function-name staging-url-generator \
  --zip-file fileb://staging-url-generator.zip
```

### 3. Update CloudFront Distribution

```bash
# Update staging distribution to use signed URLs
terraform apply -target=aws_cloudfront_distribution.staging_distribution
```

## Monitoring

### CloudWatch Metrics

- **API Gateway**: Request count, latency, error rate
- **Lambda**: Invocations, duration, errors
- **CloudFront**: Cache hit ratio, origin requests

### Logs

- **API Gateway Access Logs**: All URL generation requests
- **Lambda Logs**: Function execution details
- **CloudFront Logs**: Access patterns and security events

## Troubleshooting

### Common Issues

1. **URL Generation Fails**
   - Check Lambda function logs
   - Verify API Gateway configuration
   - Ensure CloudFront key pair is valid

2. **Signed URLs Don't Work**
   - Verify URL hasn't expired
   - Check CloudFront distribution configuration
   - Ensure key pair ID is correct

3. **Access Denied Errors**
   - Check if URL is properly signed
   - Verify path matches exactly
   - Ensure distribution allows signed URLs

### Debug Commands

```bash
# Test API endpoint
curl -X POST https://api.robertconsulting.net/staging-url \
  -H "Content-Type: application/json" \
  -d '{"path": "/", "expiration_hours": 1}'

# Check Lambda function
aws lambda invoke \
  --function-name staging-url-generator \
  --payload '{"path": "/", "expiration_hours": 1}' \
  response.json

# Verify CloudFront configuration
aws cloudfront get-distribution --id E23HB5TWK5BF44
```

## Migration from IP Whitelisting

### Step 1: Deploy New System

1. Deploy CloudFront signed URL infrastructure
2. Test URL generation and access
3. Verify staging is accessible via signed URLs

### Step 2: Update Workflows

1. Update CI/CD pipelines to use signed URLs
2. Remove IP whitelisting from WAF rules
3. Update documentation and procedures

### Step 3: Clean Up

1. Remove old IP whitelisting rules
2. Delete unused WAF configurations
3. Update monitoring and alerting

## Cost Analysis

### AWS Services Used

- **CloudFront**: No additional cost (already in use)
- **Lambda**: ~$0.20 per 1M requests
- **API Gateway**: ~$3.50 per 1M requests
- **Secrets Manager**: ~$0.40 per secret per month

### Estimated Monthly Cost

For typical usage (100 URL generations per day):
- **Lambda**: $0.01
- **API Gateway**: $0.01
- **Secrets Manager**: $0.40
- **Total**: ~$0.42/month

## Conclusion

The CloudFront signed URL approach provides a robust, secure, and cost-effective solution for staging access control that eliminates the limitations of IP whitelisting while maintaining security and providing better automation capabilities.
