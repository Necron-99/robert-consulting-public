#!/bin/bash

# Bootstrap script to create S3 bucket and DynamoDB table for Terraform state
# Run this script BEFORE configuring the S3 backend

echo "🚀 Bootstrapping Terraform S3 backend..."

# Step 1: Initialize Terraform with bootstrap configuration
echo "📦 Initializing Terraform..."
terraform init

# Step 2: Create S3 bucket and DynamoDB table
echo "🏗️  Creating S3 bucket and DynamoDB table..."
terraform apply -auto-approve

# Step 3: Show outputs
echo "📋 Backend resources created:"
terraform output

echo ""
echo "✅ Bootstrap complete! You can now configure the S3 backend."
echo ""
echo "Next steps:"
echo "1. Move bootstrap.tf to bootstrap.tf.backup"
echo "2. Run: terraform init -migrate-state"
echo "3. Follow the prompts to migrate your state to S3"
