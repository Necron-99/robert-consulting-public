#!/bin/bash

# Package Lambda function for JWT token generator

echo "📦 Packaging JWT token generator Lambda function..."

# Create temporary directory
mkdir -p /tmp/jwt-lambda
cd /tmp/jwt-lambda

# Copy Lambda function code
cp /Volumes/gitlab/robert-consulting.net/lambda/staging-token-generator/index.py .

# Install PyJWT (we'll need to include it in the package)
pip3 install PyJWT -t .

# Create ZIP file
zip -r staging-token-generator.zip .

# Move to terraform directory
mv staging-token-generator.zip /Volumes/gitlab/robert-consulting.net/terraform/

# Clean up
cd /Volumes/gitlab/robert-consulting.net
rm -rf /tmp/jwt-lambda

echo "✅ JWT token generator Lambda function packaged successfully"
echo "📁 Package location: terraform/staging-token-generator.zip"
