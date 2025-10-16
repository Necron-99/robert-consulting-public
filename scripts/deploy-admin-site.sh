#!/bin/bash
# Deploy Robert Consulting Admin Site

set -e

echo "🚀 Deploying Robert Consulting Admin Site..."

# Configuration
ADMIN_BUCKET="rc-admin-site-$(date +%Y%m%d)-$(openssl rand -hex 3)"
CLOUDFRONT_DISTRIBUTION_ID="E1TD9DYEU1B2AJ"  # Robert Consulting CloudFront
AWS_REGION="us-east-1"

echo "📋 Configuration:"
echo "   Admin Bucket: $ADMIN_BUCKET"
echo "   CloudFront: $CLOUDFRONT_DISTRIBUTION_ID"
echo "   Region: $AWS_REGION"

# Check if we're in the right directory
if [ ! -d "admin" ]; then
    echo "❌ Error: admin directory not found"
    echo "   Please run this script from the robert-consulting.net root directory"
    exit 1
fi

# Create S3 bucket
echo "🏗️  Creating S3 bucket..."
aws s3 mb "s3://$ADMIN_BUCKET" --region "$AWS_REGION"

# Set bucket policy for CloudFront access
echo "🔐 Setting bucket policy..."
cat > /tmp/admin-bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$ADMIN_BUCKET/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/$CLOUDFRONT_DISTRIBUTION_ID"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket "$ADMIN_BUCKET" --policy file:///tmp/admin-bucket-policy.json

# Upload admin files
echo "📤 Uploading admin site files..."
aws s3 sync ./admin/ "s3://$ADMIN_BUCKET/" --delete

# Set appropriate cache headers
echo "⚙️  Setting cache headers..."
aws s3 cp "s3://$ADMIN_BUCKET/" "s3://$ADMIN_BUCKET/" --recursive --metadata-directive REPLACE \
    --cache-control "public, max-age=3600" \
    --exclude "*.html" \
    --exclude "*.css" \
    --exclude "*.js"

# Set shorter cache for HTML/CSS/JS
aws s3 cp "s3://$ADMIN_BUCKET/" "s3://$ADMIN_BUCKET/" --recursive --metadata-directive REPLACE \
    --cache-control "public, max-age=300" \
    --include "*.html" \
    --include "*.css" \
    --include "*.js"

echo "✅ Admin site files uploaded to s3://$ADMIN_BUCKET"

# Create CloudFront invalidation
echo "🔄 Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --paths "/admin/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "✅ CloudFront invalidation created: $INVALIDATION_ID"

# Clean up temp file
rm -f /tmp/admin-bucket-policy.json

echo ""
echo "🎉 Admin site deployment complete!"
echo "🌐 Admin site will be available at: https://robertconsulting.net/admin/"
echo "⏱️  Changes will be live in 5-15 minutes"
echo ""
echo "📋 Next steps:"
echo "1. Wait for CloudFront invalidation to complete"
echo "2. Test admin site access"
echo "3. Test easter egg functionality"
echo ""
echo "🔧 Bucket name: $ADMIN_BUCKET"
echo "🔄 Invalidation ID: $INVALIDATION_ID"
