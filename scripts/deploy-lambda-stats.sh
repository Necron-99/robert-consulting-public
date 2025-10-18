#!/bin/bash

# Deploy Lambda Stats Refresher Function
# Run this script from the project root directory

set -e

echo "🚀 Deploying Lambda Stats Refresher Function..."

# Check if we're in the right directory
if [ ! -f "lambda/stats-refresher/package.json" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
cd lambda/stats-refresher
npm install --production
cd ../..

# Create deployment package
echo "📦 Creating deployment package..."
cd lambda/stats-refresher
zip -r ../stats-refresher.zip . -x "*.git*" "*.md" "node_modules/.cache/*"
cd ../..

# Create IAM role if it doesn't exist
echo "🔐 Creating IAM role..."
ROLE_ARN=$(aws iam get-role --role-name dashboard-stats-refresher-role --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ]; then
    echo "Creating IAM role..."
    
    # Create trust policy
    cat > /tmp/trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

    # Create the role
    aws iam create-role \
        --role-name dashboard-stats-refresher-role \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Role for dashboard stats refresher Lambda function"

    # Create and attach policy
    cat > /tmp/lambda-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:github-token-dashboard-stats*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ce:GetCostAndUsage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::robert-consulting-website/data/dashboard-stats.json"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": "arn:aws:cloudfront::*:distribution/E36DBYPHUUKB3V"
        }
    ]
}
EOF

    aws iam put-role-policy \
        --role-name dashboard-stats-refresher-role \
        --policy-name dashboard-stats-refresher-policy \
        --policy-document file:///tmp/lambda-policy.json

    # Wait for role to be ready
    echo "⏳ Waiting for IAM role to be ready..."
    sleep 10
    
    ROLE_ARN=$(aws iam get-role --role-name dashboard-stats-refresher-role --query 'Role.Arn' --output text)
fi

echo "✅ IAM Role ARN: $ROLE_ARN"

# Create or update Lambda function
echo "🔧 Creating/updating Lambda function..."
aws lambda create-function \
    --function-name dashboard-stats-refresher \
    --runtime nodejs20.x \
    --role "$ROLE_ARN" \
    --handler index.handler \
    --zip-file fileb://lambda/stats-refresher.zip \
    --timeout 30 \
    --memory-size 256 \
    --environment Variables='{
        "GITHUB_USERNAME":"Necron-99",
        "GITHUB_TOKEN_SECRET_ID":"github-token-dashboard-stats",
        "CLOUDFRONT_DISTRIBUTION_ID":"E36DBYPHUUKB3V",
        "PROD_BUCKET":"robert-consulting-website",
        "AWS_REGION":"us-east-1",
        "LOG_LEVEL":"INFO"
    }' \
    --tags '{
        "Name":"dashboard-stats-refresher",
        "Environment":"production",
        "Purpose":"dashboard-stats"
    }' \
    2>/dev/null || \
aws lambda update-function-code \
    --function-name dashboard-stats-refresher \
    --zip-file fileb://lambda/stats-refresher.zip

# Update function configuration if it exists
aws lambda update-function-configuration \
    --function-name dashboard-stats-refresher \
    --timeout 30 \
    --memory-size 256 \
    --environment Variables='{
        "GITHUB_USERNAME":"Necron-99",
        "GITHUB_TOKEN_SECRET_ID":"github-token-dashboard-stats",
        "CLOUDFRONT_DISTRIBUTION_ID":"E36DBYPHUUKB3V",
        "PROD_BUCKET":"robert-consulting-website",
        "AWS_REGION":"us-east-1",
        "LOG_LEVEL":"INFO"
    }' \
    2>/dev/null || echo "Function configuration updated"

# Create CloudWatch log group
echo "📊 Creating CloudWatch log group..."
aws logs create-log-group \
    --log-group-name "/aws/lambda/dashboard-stats-refresher" \
    --retention-in-days 14 \
    2>/dev/null || echo "Log group already exists"

# Create Secrets Manager secret
echo "🔐 Creating Secrets Manager secret..."
aws secretsmanager create-secret \
    --name github-token-dashboard-stats \
    --description "GitHub personal access token for dashboard statistics" \
    --secret-string '{"token":"your-github-token-here"}' \
    2>/dev/null || echo "Secret already exists"

# Test the function
echo "🧪 Testing Lambda function..."
aws lambda invoke \
    --function-name dashboard-stats-refresher \
    --payload '{}' \
    /tmp/lambda-test-response.json

if [ $? -eq 0 ]; then
    echo "✅ Lambda function deployed and tested successfully!"
    echo "📋 Next steps:"
    echo "1. Update the GitHub token in Secrets Manager:"
    echo "   aws secretsmanager update-secret --secret-id github-token-dashboard-stats --secret-string '{\"token\":\"your-actual-github-token\"}'"
    echo ""
    echo "2. Test the function manually:"
    echo "   aws lambda invoke --function-name dashboard-stats-refresher --payload '{}' response.json"
    echo ""
    echo "3. Check the generated stats file:"
    echo "   aws s3 ls s3://robert-consulting-website/data/"
else
    echo "❌ Lambda function test failed. Check CloudWatch logs for details."
fi

# Cleanup
rm -f /tmp/trust-policy.json /tmp/lambda-policy.json /tmp/lambda-test-response.json
rm -f lambda/stats-refresher.zip

echo "🎉 Deployment complete!"

