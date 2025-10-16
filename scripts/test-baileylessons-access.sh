#!/bin/bash
# Test access to Bailey Lessons client account

set -e

echo "🧪 Testing Bailey Lessons client account access..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI not configured"
    exit 1
fi

echo "✅ AWS CLI is configured"

# Show current account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
echo "📋 Current AWS account: $CURRENT_ACCOUNT"

# Assume role into Bailey Lessons client account
echo "🔄 Assuming role into Bailey Lessons client account..."
ROLE_ARN="arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OrganizationAccountAccessRole"
SESSION_NAME="baileylessons-test-$(date +%s)"

# Assume the role and get temporary credentials
CREDENTIALS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to assume role into Bailey Lessons account"
    echo "   Please check:"
    echo "   1. You have permission to assume the OrganizationAccountAccessRole"
    echo "   2. The role exists in account ${data.aws_caller_identity.current.account_id}"
    echo "   3. Your AWS credentials are properly configured"
    exit 1
fi

# Extract credentials
ACCESS_KEY=$(echo $CREDENTIALS | cut -d' ' -f1)
SECRET_KEY=$(echo $CREDENTIALS | cut -d' ' -f2)
SESSION_TOKEN=$(echo $CREDENTIALS | cut -d' ' -f3)

# Set environment variables for the assumed role
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"

# Verify we're now in the correct account
NEW_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
EXPECTED_ACCOUNT="${data.aws_caller_identity.current.account_id}"

if [ "$NEW_ACCOUNT" != "$EXPECTED_ACCOUNT" ]; then
    echo "❌ Error: Failed to assume role into Bailey Lessons account"
    echo "   Current account: $NEW_ACCOUNT"
    echo "   Expected account: $EXPECTED_ACCOUNT"
    exit 1
fi

echo "✅ Successfully assumed role into Bailey Lessons account ($NEW_ACCOUNT)"

# Test S3 bucket access
echo "🔍 Testing S3 bucket access..."
S3_BUCKET_NAME="baileylessons-production-static"

if aws s3 ls "s3://$S3_BUCKET_NAME" > /dev/null 2>&1; then
    echo "✅ S3 bucket access successful: $S3_BUCKET_NAME"
    
    # List bucket contents
    echo "📋 S3 bucket contents:"
    aws s3 ls "s3://$S3_BUCKET_NAME" --human-readable
else
    echo "❌ Error: Cannot access S3 bucket '$S3_BUCKET_NAME'"
    exit 1
fi

# Test CloudFront access
echo "🔍 Testing CloudFront access..."
CLOUDFRONT_DISTRIBUTION_ID="E23X7BS3VXFFFZ"

if aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" > /dev/null 2>&1; then
    echo "✅ CloudFront distribution access successful: $CLOUDFRONT_DISTRIBUTION_ID"
    
    # Get distribution status
    STATUS=$(aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" --query 'Distribution.Status' --output text)
    echo "📋 CloudFront status: $STATUS"
else
    echo "❌ Error: Cannot access CloudFront distribution '$CLOUDFRONT_DISTRIBUTION_ID'"
    exit 1
fi

echo ""
echo "🎉 All tests passed! You have full access to Bailey Lessons resources:"
echo "   ✅ Role assumption successful"
echo "   ✅ S3 bucket access: $S3_BUCKET_NAME"
echo "   ✅ CloudFront access: $CLOUDFRONT_DISTRIBUTION_ID"
echo ""
echo "🚀 You can now run the deployment scripts:"
echo "   ./scripts/update-baileylessons-content.sh"
echo "   ./scripts/deploy-to-baileylessons.sh"
