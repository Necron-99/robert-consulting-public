#!/bin/bash

# Deploy Staging Environment
# Creates a production-mirror staging environment with restricted access

set -e

echo "🚀 Deploying Staging Environment..."
echo "=================================="

# Check if we're in the right directory
if [ ! -f "terraform/staging-environment.tf" ]; then
    echo "❌ Error: staging-environment.tf not found. Please run from repository root."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS credentials configured"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the staging infrastructure
echo "📋 Planning staging infrastructure..."
terraform plan -target=aws_s3_bucket.staging_website_bucket \
               -target=aws_s3_bucket_versioning.staging_website_bucket \
               -target=aws_s3_bucket_server_side_encryption_configuration.staging_website_bucket \
               -target=aws_s3_bucket_public_access_block.staging_website_bucket \
               -target=aws_s3_bucket_website_configuration.staging_website_bucket \
               -target=aws_s3_bucket_policy.staging_website_bucket \
               -target=aws_cloudfront_response_headers_policy.staging_security_headers \
               -target=aws_cloudfront_distribution.staging_website \
               -target=aws_acm_certificate.staging_ssl_cert \
               -target=aws_route53_record.staging_ssl_validation \
               -target=aws_acm_certificate_validation.staging_ssl_cert \
               -target=aws_route53_record.staging_domain \
               -target=aws_wafv2_ip_set.staging_allowed_ips \
               -target=aws_wafv2_web_acl.staging_waf \
               -target=aws_wafv2_web_acl_association.staging_waf_association \
               -target=aws_sns_topic.staging_alerts \
               -target=aws_cloudwatch_metric_alarm.staging_high_error_rate

# Apply the staging infrastructure
echo "🏗️ Creating staging infrastructure..."
terraform apply -target=aws_s3_bucket.staging_website_bucket \
                -target=aws_s3_bucket_versioning.staging_website_bucket \
                -target=aws_s3_bucket_server_side_encryption_configuration.staging_website_bucket \
                -target=aws_s3_bucket_public_access_block.staging_website_bucket \
                -target=aws_s3_bucket_website_configuration.staging_website_bucket \
                -target=aws_s3_bucket_policy.staging_website_bucket \
                -target=aws_cloudfront_response_headers_policy.staging_security_headers \
                -target=aws_cloudfront_distribution.staging_website \
                -target=aws_acm_certificate.staging_ssl_cert \
                -target=aws_route53_record.staging_ssl_validation \
                -target=aws_acm_certificate_validation.staging_ssl_cert \
                -target=aws_route53_record.staging_domain \
                -target=aws_wafv2_ip_set.staging_allowed_ips \
                -target=aws_wafv2_web_acl.staging_waf \
                -target=aws_wafv2_web_acl_association.staging_waf_association \
                -target=aws_sns_topic.staging_alerts \
                -target=aws_cloudwatch_metric_alarm.staging_high_error_rate \
                -auto-approve

echo "📊 Staging infrastructure outputs:"
echo "  Bucket Name: $(terraform output -raw staging_bucket_name)"
echo "  CloudFront URL: $(terraform output -raw staging_cloudfront_url)"
echo "  Domain URL: $(terraform output -raw staging_domain_url)"
echo "  WAF ARN: $(terraform output -raw staging_waf_arn)"

echo ""
echo "✅ Staging environment deployed successfully!"
echo ""
echo "🔧 Next Steps:"
echo "1. Add your IP addresses to the staging_allowed_ips variable in staging-environment.tf"
echo "2. Run 'terraform apply' again to update the WAF IP restrictions"
echo "3. Deploy website content to staging: aws s3 sync ../website/ s3://$(terraform output -raw staging_bucket_name) --delete"
echo "4. Test the staging environment: https://staging.robertconsulting.net"
echo ""
echo "🛡️ Security Features:"
echo "- IP-based access control (WAF)"
echo "- Rate limiting"
echo "- Suspicious user agent blocking"
echo "- All production security headers"
echo "- SSL/TLS encryption"
echo "- CloudWatch monitoring"
echo ""
echo "💰 Cost Optimization:"
echo "- PriceClass_100 (US, Canada, Europe only)"
echo "- Minimal monitoring (only error rate alarm)"
echo "- No additional Route53 hosted zone needed"
