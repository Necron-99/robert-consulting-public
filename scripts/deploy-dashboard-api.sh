#!/bin/bash

# Deploy Dashboard API
# Updates the dashboard API Lambda function (Cost Explorer removed to eliminate costs)

set -e

echo "🚀 Deploying Dashboard API with Real AWS Data Integration..."

# Navigate to lambda directory
cd "$(dirname "$0")/../lambda"

# Install dependencies
echo "📦 Installing AWS SDK v3 dependencies..."
npm install

# Create deployment package
echo "📦 Creating deployment package..."
zip -r dashboard-api.zip dashboard-api.js node_modules/ package.json

# Deploy to AWS Lambda
echo "🚀 Deploying to AWS Lambda..."
aws lambda update-function-code \
    --function-name robert-consulting-dashboard-api \
    --zip-file fileb://dashboard-api.zip \
    --region us-east-1

# Update function configuration to ensure it has the right permissions
echo "🔧 Updating Lambda function configuration..."
aws lambda update-function-configuration \
    --function-name robert-consulting-dashboard-api \
    --timeout 30 \
    --memory-size 256 \
    --region us-east-1

# Test the function
echo "🧪 Testing the updated function..."
aws lambda invoke \
    --function-name robert-consulting-dashboard-api \
    --region us-east-1 \
    --payload '{}' \
    response.json

echo "📊 Function response:"
cat response.json | jq '.'

# Clean up
rm -f dashboard-api.zip response.json

echo "✅ Dashboard API deployment completed successfully!"
echo "🔗 API Endpoint: https://lbfggdldp3.execute-api.us-east-1.amazonaws.com/prod/dashboard-data"
echo "📊 The dashboard uses static cost data (Cost Explorer removed to eliminate costs)"