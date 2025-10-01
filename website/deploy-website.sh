#!/bin/bash

# Website Deployment Script
# Decoupled from Terraform infrastructure management

set -e

# Configuration
BUCKET_NAME="robert-consulting-website"
CLOUDFRONT_DISTRIBUTION_ID=""
REGION="us-east-1"
WEBSITE_DIR="website"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get CloudFront distribution ID from Terraform state
get_cloudfront_id() {
    if [ -f "../terraform/terraform.tfstate" ]; then
        CLOUDFRONT_DISTRIBUTION_ID=$(cd ../terraform && terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
    fi
    
    if [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        log_warning "CloudFront distribution ID not found in Terraform state"
        log_info "You can find it in AWS Console or set it manually:"
        log_info "export CLOUDFRONT_DISTRIBUTION_ID=your-distribution-id"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    # Check if bucket exists
    if ! aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
        log_error "S3 bucket '$BUCKET_NAME' does not exist"
        log_info "Please run 'cd terraform && terraform apply' first"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Sync website files to S3
deploy_to_s3() {
    log_info "Deploying website files to S3..."
    
    # Sync files with appropriate cache headers
    aws s3 sync "$WEBSITE_DIR/" "s3://$BUCKET_NAME/" \
        --delete \
        --cache-control "max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.json"
    
    # Sync HTML files with shorter cache
    aws s3 sync "$WEBSITE_DIR/" "s3://$BUCKET_NAME/" \
        --cache-control "max-age=3600" \
        --include "*.html" \
        --include "*.json"
    
    log_success "Website files deployed to S3"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        log_info "Invalidating CloudFront cache..."
        
        local invalidation_id
        invalidation_id=$(aws cloudfront create-invalidation \
            --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --paths "/*" \
            --query 'Invalidation.Id' \
            --output text)
        
        log_success "CloudFront invalidation created: $invalidation_id"
        
        # Wait for invalidation to complete (optional)
        if [ "${WAIT_FOR_INVALIDATION:-false}" = "true" ]; then
            log_info "Waiting for invalidation to complete..."
            aws cloudfront wait invalidation-completed \
                --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
                --id "$invalidation_id"
            log_success "CloudFront invalidation completed"
        fi
    else
        log_warning "Skipping CloudFront invalidation (no distribution ID)"
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if index.html exists
    if aws s3 ls "s3://$BUCKET_NAME/index.html" &> /dev/null; then
        log_success "index.html found in S3"
    else
        log_error "index.html not found in S3"
        exit 1
    fi
    
    # Get website URL
    local website_url
    website_url=$(aws s3api get-bucket-website --bucket "$BUCKET_NAME" --query 'WebsiteConfiguration.IndexDocument.Suffix' --output text 2>/dev/null || echo "")
    
    if [ -n "$website_url" ]; then
        log_success "Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
    fi
    
    if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        local cloudfront_domain
        cloudfront_domain=$(aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" --query 'Distribution.DomainName' --output text 2>/dev/null || echo "")
        if [ -n "$cloudfront_domain" ]; then
            log_success "CloudFront URL: https://$cloudfront_domain"
        fi
    fi
}

# Show deployment summary
show_summary() {
    log_info "Deployment Summary:"
    echo "==================="
    echo "Bucket: $BUCKET_NAME"
    echo "Region: $REGION"
    echo "CloudFront ID: ${CLOUDFRONT_DISTRIBUTION_ID:-Not configured}"
    echo "Website Directory: $WEBSITE_DIR"
    echo ""
    
    if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        echo "🌐 CloudFront URL: https://$(aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" --query 'Distribution.DomainName' --output text)"
    fi
    echo "🌐 S3 Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
}

# Main deployment function
main() {
    log_info "Starting website deployment..."
    
    get_cloudfront_id
    check_prerequisites
    deploy_to_s3
    invalidate_cloudfront
    verify_deployment
    show_summary
    
    log_success "✅ Website deployment completed successfully!"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "check")
        check_prerequisites
        verify_deployment
        ;;
    "invalidate")
        get_cloudfront_id
        invalidate_cloudfront
        ;;
    "sync")
        check_prerequisites
        deploy_to_s3
        ;;
    *)
        echo "Usage: $0 {deploy|check|invalidate|sync}"
        echo ""
        echo "Commands:"
        echo "  deploy     - Full deployment (default)"
        echo "  check      - Check prerequisites and verify deployment"
        echo "  invalidate - Invalidate CloudFront cache only"
        echo "  sync       - Sync files to S3 only"
        echo ""
        echo "Environment Variables:"
        echo "  CLOUDFRONT_DISTRIBUTION_ID - CloudFront distribution ID"
        echo "  WAIT_FOR_INVALIDATION      - Wait for CloudFront invalidation (true/false)"
        exit 1
        ;;
esac
