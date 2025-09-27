# Deployment Guide - Robert Consulting Website

## Prerequisites

### 1. AWS CLI Setup
```bash
# Check AWS credentials
aws sts get-caller-identity

# If not configured, run:
aws configure
```

### 2. Required IAM Permissions
Your AWS user needs these permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "cloudfront:*",
                "cloudwatch:*",
                "sns:*",
                "iam:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Deployment Options

### Option 1: Using Terraform (Recommended)

#### Install Terraform
1. Download from: https://www.terraform.io/downloads
2. Extract and add to PATH
3. Verify: `terraform version`

#### Deploy Infrastructure
```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Option 2: Manual AWS CLI Deployment

#### Create S3 Bucket
```bash
# Create unique bucket name
BUCKET_NAME="robert-consulting-website-2024-$(date +%s)"

# Create bucket
aws s3 mb s3://$BUCKET_NAME

# Configure for website hosting
aws s3 website s3://$BUCKET_NAME --index-document index.html --error-document error.html

# Upload website files
aws s3 sync ../website/ s3://$BUCKET_NAME --delete
```

#### Create CloudFront Distribution
```bash
# Create CloudFront distribution (requires JSON configuration)
# This is complex - use Terraform instead
```

## Post-Deployment

### 1. Upload Website Files
```bash
# From project root
aws s3 sync website/ s3://YOUR_BUCKET_NAME --delete
```

### 2. Access Your Website
- **CloudFront URL**: `https://YOUR_DISTRIBUTION_ID.cloudfront.net`
- **S3 URL**: `http://YOUR_BUCKET_NAME.s3-website-us-east-1.amazonaws.com`

### 3. Monitor Costs
- Check AWS Cost Explorer
- Set up billing alerts
- Monitor CloudWatch metrics

## Troubleshooting

### Access Denied Errors
1. **Check IAM permissions** - Ensure user has required permissions
2. **Verify bucket name** - Must be globally unique
3. **Check region** - Ensure resources are in correct region

### Bucket Name Conflicts
- The random suffix ensures uniqueness
- If conflict occurs, change the base name in `terraform.tfvars`

### CloudFront Deployment
- Takes 15-20 minutes to fully deploy
- Use CloudFront URL, not S3 direct access
- Check distribution status in AWS Console

## Cost Monitoring

### Expected Monthly Costs
- **S3**: ~$0.003
- **CloudFront**: ~$0.86
- **CloudWatch**: ~$0.70
- **Total**: ~$1.56/month

### Cost Alerts
- Set up billing alerts for >$5/month
- Monitor CloudWatch metrics
- Review monthly in AWS Cost Explorer

## Security Notes

### S3 Bucket Security
- Public read access for website files
- Private write access (IAM user only)
- Versioning enabled for data protection

### CloudFront Security
- HTTPS enforcement
- Geographic restrictions (US/Canada/Europe)
- Compression enabled

## Next Steps

1. **Deploy Infrastructure**: Use Terraform or manual AWS CLI
2. **Upload Website**: Sync website files to S3
3. **Test Access**: Verify website loads correctly
4. **Monitor Costs**: Set up billing alerts
5. **Custom Domain**: Add Route 53 if needed

## Support

If you encounter issues:
1. Check AWS CloudTrail for detailed error logs
2. Verify IAM permissions
3. Ensure bucket name is globally unique
4. Check CloudFront distribution status
