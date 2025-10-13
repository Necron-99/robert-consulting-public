#!/bin/bash

# Package Lambda function for staging URL generator

echo "📦 Packaging Lambda function for staging URL generator..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Copy Lambda function code
cp /Volumes/gitlab/robert-consulting.net/lambda/staging-url-generator/index.py .

# Install dependencies (if any)
# pip install -r requirements.txt -t .

# Create ZIP file
zip -r staging-url-generator.zip .

# Move to project root
mv staging-url-generator.zip /Volumes/gitlab/robert-consulting.net/

# Clean up
cd /Volumes/gitlab/robert-consulting.net
rm -rf "$TEMP_DIR"

echo "✅ Lambda function packaged successfully: staging-url-generator.zip"
