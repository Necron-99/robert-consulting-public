#!/bin/bash

# Update IAM permissions for terraform-stats-refresher Lambda function
# This adds the missing permissions needed to count AWS resources

echo "🔧 Updating IAM permissions for terraform-stats-refresher..."

# Create a new policy document with all required permissions
cat > terraform-stats-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:logs:*:*:*"
        },
        # Cost Explorer permissions removed to eliminate costs
        {
            "Action": [
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricData",
                "cloudwatch:DescribeAlarms"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:ListObjectsV2",
                "s3:ListAllMyBuckets",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::robert-consulting-website",
                "arn:aws:s3:::robert-consulting-website/*",
                "arn:aws:s3:::robert-consulting-staging-website",
                "arn:aws:s3:::robert-consulting-staging-website/*",
                "arn:aws:s3:::robert-consulting-cache",
                "arn:aws:s3:::robert-consulting-cache/*"
            ]
        },
        {
            "Action": [
                "route53:ListResourceRecordSets",
                "route53:GetHostedZone",
                "route53:ListHostedZones"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:secretsmanager:us-east-1:228480945348:secret:github-token-dashboard-stats*"
        },
        {
            "Action": [
                "cloudfront:ListDistributions",
                "cloudfront:GetDistribution"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "wafv2:ListWebACLs",
                "wafv2:GetWebACL"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "apigateway:GET",
                "apigateway:GetRestApis"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "lambda:ListFunctions",
                "lambda:GetFunction"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "iam:ListRoles",
                "iam:ListPolicies",
                "iam:GetRole",
                "iam:GetPolicy"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF

# Update the existing policy
echo "📝 Updating IAM policy..."
aws iam put-role-policy \
    --role-name robert-consulting-dashboard-api-role \
    --policy-name robert-consulting-dashboard-api-policy \
    --policy-document file://terraform-stats-policy.json \
    --region us-east-1

# Clean up
rm terraform-stats-policy.json

echo "✅ IAM permissions updated successfully!"
echo ""
echo "🧪 Testing the terraform-stats-refresher Lambda function..."

# Test the Lambda function
aws lambda invoke \
    --function-name robert-consulting-terraform-stats-refresher \
    --region us-east-1 \
    --payload '{}' \
    terraform-stats-test-response.json

echo "📊 Lambda function response:"
cat terraform-stats-test-response.json | jq '.'

# Clean up test file
rm terraform-stats-test-response.json

echo ""
echo "🎉 Terraform stats refresher should now have proper permissions!"
echo "💡 The dashboard should show real AWS resource counts on the next refresh."
