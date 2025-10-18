#!/bin/bash

# Package Lambda function for staging token generator

echo "📦 Packaging Lambda function for staging token generator..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Copy Lambda function code
cp /Volumes/gitlab/robert-consulting.net/lambda/staging-token-generator/index.py .

# Install dependencies (if any)
# pip install -r requirements.txt -t .

# Create ZIP file
zip -r staging-token-generator.zip .

# Move to project root
mv staging-token-generator.zip /Volumes/gitlab/robert-consulting.net/

# Clean up
cd /Volumes/gitlab/robert-consulting.net
rm -rf "$TEMP_DIR"

echo "✅ Lambda function packaged successfully: staging-token-generator.zip"
