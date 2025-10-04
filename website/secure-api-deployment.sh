#!/bin/bash

# Secure API Deployment Script
# This script deploys the website with secure API configuration

set -e

# Configuration
API_ENDPOINT_PLACEHOLDER="[API_ENDPOINT_PLACEHOLDER]"
API_KEY_PLACEHOLDER="[API_KEY_PLACEHOLDER]"
BUCKET_NAME="robert-consulting-website-2024-bd900b02"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
    
    log_success "AWS CLI is configured"
}

# Get API Gateway endpoint from Terraform
get_api_endpoint() {
    log_info "Getting API Gateway endpoint from Terraform..."
    
    if [ -f "../terraform/terraform.tfstate" ]; then
        API_ENDPOINT=$(cd ../terraform && terraform output -raw contact_form_api_url 2>/dev/null || echo "")
        if [ -n "$API_ENDPOINT" ]; then
            log_success "API endpoint found: $API_ENDPOINT"
            echo "$API_ENDPOINT"
        else
            log_warning "Could not get API endpoint from Terraform"
            echo ""
        fi
    else
        log_warning "Terraform state not found"
        echo ""
    fi
}

# Get API key from Terraform
get_api_key() {
    log_info "Getting API key from Terraform..."
    
    if [ -f "../terraform/terraform.tfstate" ]; then
        API_KEY=$(cd ../terraform && terraform output -raw contact_form_api_key 2>/dev/null || echo "")
        if [ -n "$API_KEY" ]; then
            log_success "API key found"
            echo "$API_KEY"
        else
            log_warning "Could not get API key from Terraform"
            echo ""
        fi
    else
        log_warning "Terraform state not found"
        echo ""
    fi
}

# Replace API placeholders with actual values
configure_api() {
    local api_endpoint="$1"
    local api_key="$2"
    
    log_info "Configuring API endpoints..."
    
    if [ -n "$api_endpoint" ] && [ -n "$api_key" ]; then
        # Create backup
        cp js/api-config.js js/api-config.js.bak
        
        # Use shell script for safe replacement
        ./configure-api.sh "$api_endpoint" "$api_key"
        log_success "API configuration updated"
    else
        log_warning "Using placeholder values - API will not work until properly configured"
    fi
}

# Deploy to S3
deploy_to_s3() {
    log_info "Deploying website to S3..."
    
    # Sync files to S3
    aws s3 sync . s3://$BUCKET_NAME/ \
        --exclude "*.sh" \
        --exclude "*.md" \
        --exclude "*.json" \
        --exclude "node_modules/*" \
        --exclude ".git/*" \
        --exclude "*.bak" \
        --delete
    
    log_success "Website deployed to S3"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log_info "Invalidating CloudFront cache..."
    
    # Get CloudFront distribution ID
    DISTRIBUTION_ID=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?Origins.Items[0].DomainName=='$BUCKET_NAME.s3-website-$REGION.amazonaws.com'].Id" \
        --output text)
    
    if [ -n "$DISTRIBUTION_ID" ]; then
        aws cloudfront create-invalidation \
            --distribution-id "$DISTRIBUTION_ID" \
            --paths "/*"
        
        log_success "CloudFront cache invalidated"
    else
        log_warning "Could not find CloudFront distribution"
    fi
}

# Restore backup files
restore_backups() {
    log_info "Restoring backup files..."
    
    if [ -f "js/api-config.js.bak" ]; then
        mv js/api-config.js.bak js/api-config.js
        log_success "Backup files restored"
    fi
}

# Main deployment function
main() {
    log_info "Starting secure API deployment..."
    
    # Check prerequisites
    check_aws_cli
    
    # Get API configuration
    API_ENDPOINT=$(get_api_endpoint)
    API_KEY=$(get_api_key)
    
    # Configure API
    configure_api "$API_ENDPOINT" "$API_KEY"
    
    # Deploy to S3
    deploy_to_s3
    
    # Invalidate CloudFront
    invalidate_cloudfront
    
    # Restore backups
    restore_backups
    
    log_success "Secure API deployment completed!"
    
    # Display URLs
    echo ""
    log_info "Website URLs:"
    echo "  CloudFront: https://d24d7iql53878z.cloudfront.net"
    echo "  S3 Website: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
    
    if [ -n "$API_ENDPOINT" ]; then
        echo "  API Endpoint: $API_ENDPOINT"
    fi
}

# Run main function
main "$@"
