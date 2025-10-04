#!/bin/bash

# Deploy Contact Form Lambda Function
# This script packages and deploys the Lambda function for contact form processing

echo "🚀 Deploying Contact Form Lambda Function..."

# Navigate to Lambda directory
cd "$(dirname "$0")/../../lambda"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create deployment package
echo "📦 Creating deployment package..."
zip -r contact-form.zip . -x "*.git*" "*.md" "deploy-lambda.sh"

# Deploy to AWS Lambda
echo "☁️ Deploying to AWS Lambda..."
aws lambda update-function-code \
    --function-name contact-form-api \
    --zip-file fileb://contact-form.zip \
    --region us-east-1

if [ $? -eq 0 ]; then
    echo "✅ Lambda function deployed successfully!"
    echo "📧 Contact form will now send emails to info@robertconsulting.net"
else
    echo "❌ Lambda deployment failed!"
    exit 1
fi

# Clean up
rm contact-form.zip

echo "🎉 Contact form API deployment complete!"
