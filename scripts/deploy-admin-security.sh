#!/bin/bash

# Deploy Enhanced Admin Security
# This script deploys the enhanced security features for the admin site

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
LAMBDA_DIR="lambda"
ADMIN_DIR="admin"
BACKUP_DIR="backup/admin-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}🔐 DEPLOYING ENHANCED ADMIN SECURITY${NC}"
echo "=================================="

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 22 ]; then
    echo -e "${YELLOW}⚠️  Node.js version is $NODE_VERSION, but Node.js 22+ is recommended for Lambda${NC}"
    echo -e "${YELLOW}   Lambda now supports Node.js 22 LTS (Node.js 18 is EOL)${NC}"
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Backup existing admin files
echo -e "${YELLOW}💾 Creating backup of existing admin files...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$ADMIN_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created at $BACKUP_DIR${NC}"

# Install Lambda dependencies
echo -e "${YELLOW}📦 Installing Lambda dependencies...${NC}"
cd "$LAMBDA_DIR"
npm install --production
cd ..
echo -e "${GREEN}✅ Lambda dependencies installed${NC}"

# Initialize Terraform
echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"
cd "$TERRAFORM_DIR"
terraform init
echo -e "${GREEN}✅ Terraform initialized${NC}"

# Plan the deployment
echo -e "${YELLOW}📋 Planning Terraform deployment...${NC}"
terraform plan -var="admin_enhanced_security_enabled=true" -out=admin-security.tfplan

# Ask for confirmation
echo -e "${YELLOW}⚠️  Review the plan above. Do you want to proceed with the deployment? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Deployment cancelled${NC}"
    exit 1
fi

# Apply the deployment
echo -e "${YELLOW}🚀 Applying Terraform changes...${NC}"
terraform apply admin-security.tfplan

# Get outputs
echo -e "${YELLOW}📤 Getting deployment outputs...${NC}"
ADMIN_URL=$(terraform output -raw admin_url 2>/dev/null || echo "Not available")
WAF_ARN=$(terraform output -raw admin_waf_web_acl_arn 2>/dev/null || echo "Not available")
SECRET_ARN=$(terraform output -raw admin_security_secret_arn 2>/dev/null || echo "Not available")

# Deploy admin files to S3
echo -e "${YELLOW}📤 Deploying admin files to S3...${NC}"
ADMIN_BUCKET=$(terraform output -raw admin_bucket_name 2>/dev/null || echo "")
if [ -n "$ADMIN_BUCKET" ]; then
    aws s3 sync "../$ADMIN_DIR/" "s3://$ADMIN_BUCKET/" --delete
    echo -e "${GREEN}✅ Admin files deployed to S3${NC}"
else
    echo -e "${YELLOW}⚠️  Could not determine admin bucket name${NC}"
fi

# Invalidate CloudFront cache
echo -e "${YELLOW}🔄 Invalidating CloudFront cache...${NC}"
DISTRIBUTION_ID=$(terraform output -raw admin_distribution_id 2>/dev/null || echo "")
if [ -n "$DISTRIBUTION_ID" ]; then
    aws cloudfront create-invalidation --distribution-id "$DISTRIBUTION_ID" --paths "/*"
    echo -e "${GREEN}✅ CloudFront cache invalidated${NC}"
else
    echo -e "${YELLOW}⚠️  Could not determine CloudFront distribution ID${NC}"
fi

cd ..

# Display deployment summary
echo -e "${GREEN}🎉 ENHANCED ADMIN SECURITY DEPLOYMENT COMPLETE!${NC}"
echo "=============================================="
echo -e "${BLUE}📊 Deployment Summary:${NC}"
echo "• Admin URL: $ADMIN_URL"
echo "• WAF ARN: $WAF_ARN"
echo "• Security Secret ARN: $SECRET_ARN"
echo "• Backup Location: $BACKUP_DIR"
echo ""
echo -e "${BLUE}🔐 Security Features Deployed:${NC}"
echo "• Multi-factor authentication (MFA)"
echo "• IP address restrictions"
echo "• Session management with JWT tokens"
echo "• Comprehensive audit logging"
echo "• Enhanced WAF protection"
echo "• Rate limiting and DDoS protection"
echo "• Brute force protection"
echo "• Secure session cookies"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo "1. Update the admin_allowed_ips variable with your IP addresses"
echo "2. The MFA secret is stored in AWS Secrets Manager"
echo "3. All admin access is now logged and monitored"
echo "4. Sessions expire after 30 minutes of inactivity"
echo "5. Failed login attempts are limited to 3 per IP"
echo ""
echo -e "${GREEN}✅ Admin site is now secured with enterprise-grade security!${NC}"

# Clean up
rm -f "$TERRAFORM_DIR/admin-security.tfplan"
