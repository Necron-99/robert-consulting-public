#!/bin/bash

# [CLIENT_NAME] Content Deployment Script
# This script deploys website content to S3 and invalidates CloudFront

set -e

# Configuration
CLIENT_NAME="${CLIENT_NAME:-[CLIENT_NAME]}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting content deployment for $CLIENT_NAME${NC}"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ AWS CLI not configured. Please run 'aws configure'${NC}"
    exit 1
fi

# Get S3 bucket name from SSM Parameter Store
echo -e "${YELLOW}📦 Getting S3 bucket name...${NC}"
BUCKET_NAME=$(aws ssm get-parameter --name "/clients/$CLIENT_NAME/s3-bucket" --query "Parameter.Value" --output text 2>/dev/null)

if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ Could not find S3 bucket for $CLIENT_NAME${NC}"
    echo "Make sure the infrastructure has been deployed and SSM parameters are set"
    exit 1
fi

echo -e "${GREEN}✅ Found S3 bucket: $BUCKET_NAME${NC}"

# Get CloudFront distribution ID
echo -e "${YELLOW}🌐 Getting CloudFront distribution ID...${NC}"
DISTRIBUTION_ID=$(aws ssm get-parameter --name "/clients/$CLIENT_NAME/cloudfront-distribution" --query "Parameter.Value" --output text 2>/dev/null)

if [ -z "$DISTRIBUTION_ID" ]; then
    echo -e "${RED}❌ Could not find CloudFront distribution for $CLIENT_NAME${NC}"
    echo "Make sure the infrastructure has been deployed and SSM parameters are set"
    exit 1
fi

echo -e "${GREEN}✅ Found CloudFront distribution: $DISTRIBUTION_ID${NC}"

# Deploy static assets with long cache
echo -e "${YELLOW}📁 Deploying static assets...${NC}"
aws s3 sync website/ "s3://$BUCKET_NAME" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "*.css" \
    --exclude "*.js" \
    --exclude "*.json"

# Deploy HTML/CSS/JS with shorter cache
echo -e "${YELLOW}📄 Deploying HTML/CSS/JS files...${NC}"
aws s3 sync website/ "s3://$BUCKET_NAME" \
    --delete \
    --cache-control "public, max-age=3600" \
    --include "*.html" \
    --include "*.css" \
    --include "*.js" \
    --include "*.json"

# Invalidate CloudFront cache
echo -e "${YELLOW}🔄 Invalidating CloudFront cache...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query "Invalidation.Id" \
    --output text)

echo -e "${GREEN}✅ CloudFront invalidation created: $INVALIDATION_ID${NC}"

# Wait for invalidation to complete (optional)
echo -e "${YELLOW}⏳ Waiting for invalidation to complete...${NC}"
aws cloudfront wait invalidation-completed \
    --distribution-id "$DISTRIBUTION_ID" \
    --id "$INVALIDATION_ID"

echo -e "${GREEN}🎉 Content deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Website: https://[CLIENT_DOMAIN]${NC}"
echo -e "${GREEN}📦 S3 Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}🚀 CloudFront: $DISTRIBUTION_ID${NC}"
echo -e "${GREEN}🔄 Invalidation: $INVALIDATION_ID${NC}"
