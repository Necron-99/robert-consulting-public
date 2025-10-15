#!/bin/bash

# Deploy Dashboard API Lambda Function
# This script packages and deploys the Lambda function for real-time AWS data

set -e

echo "🚀 Deploying Dashboard API Lambda Function"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "lambda/dashboard-api.js" ]; then
    echo "❌ Error: lambda/dashboard-api.js not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Deploy using Terraform
echo "🏗️ Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan -target=aws_lambda_function.dashboard_api -target=aws_api_gateway_rest_api.dashboard_api

# Apply the changes
echo "🚀 Applying Terraform changes..."
terraform apply -target=aws_lambda_function.dashboard_api -target=aws_api_gateway_rest_api.dashboard_api -auto-approve

# Get the API Gateway URL
echo "📡 Getting API Gateway URL..."
API_URL=$(terraform output -raw dashboard_api_url 2>/dev/null || echo "Not available")

echo ""
echo "✅ Dashboard API deployed successfully!"
echo "🌐 API URL: $API_URL"
echo ""
echo "📝 Next steps:"
echo "1. Update dashboard-script.js to use the new API URL"
echo "2. Deploy the updated dashboard to S3"
echo "3. Test the real-time data functionality"
echo ""

# Clean up
echo "🧹 Cleaning up..."
rm -f dashboard-api.zip

echo "🎉 Deployment complete!"
