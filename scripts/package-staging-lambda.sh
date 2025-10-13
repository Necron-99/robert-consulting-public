#!/bin/bash

# Package Lambda function for staging URL generator

echo "📦 Packaging staging URL generator Lambda function..."

# Create temporary directory
mkdir -p /tmp/staging-lambda
cd /tmp/staging-lambda

# Copy Lambda function code
cp /Volumes/gitlab/robert-consulting.net/lambda/staging-url-generator/index.py .

# Create ZIP file
zip -r staging-url-generator.zip index.py

# Move to terraform directory
mv staging-url-generator.zip /Volumes/gitlab/robert-consulting.net/terraform/

# Clean up
cd /Volumes/gitlab/robert-consulting.net
rm -rf /tmp/staging-lambda

echo "✅ Lambda function packaged successfully"
echo "📁 Package location: terraform/staging-url-generator.zip"
