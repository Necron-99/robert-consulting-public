#!/bin/bash

# Client Content Deployment Script
# Deploys content from client repositories to infrastructure managed in this repo

set -e

# Configuration
CLIENT_NAME="${1:-}"
CLIENT_REPO="${2:-}"
BUCKET_NAME="${3:-}"
CLOUDFRONT_DISTRIBUTION_ID="${4:-}"
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Usage function
usage() {
    echo "Usage: $0 <client_name> <client_repo> <bucket_name> <cloudfront_distribution_id>"
    echo ""
    echo "Parameters:"
    echo "  client_name              - Name of the client (e.g., baileylessons)"
    echo "  client_repo              - GitHub repository (e.g., username/baileylessons.com)"
    echo "  bucket_name              - S3 bucket name for the client"
    echo "  cloudfront_distribution_id - CloudFront distribution ID"
    echo ""
    echo "Example:"
    echo "  $0 baileylessons username/baileylessons.com baileylessons-website E1TD9DYEU1B2AJ"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required parameters
    if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_REPO" ] || [ -z "$BUCKET_NAME" ] || [ -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        log_error "Missing required parameters"
        usage
    fi
    
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
        log_info "Please create the bucket first or check the bucket name"
        exit 1
    fi
    
    # Check if CloudFront distribution exists
    if ! aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" &> /dev/null; then
        log_error "CloudFront distribution '$CLOUDFRONT_DISTRIBUTION_ID' does not exist"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Clone or update client repository
setup_client_repo() {
    local temp_dir="/tmp/client-deploy-$CLIENT_NAME-$(date +%s)"
    
    log_info "Setting up client repository: $CLIENT_REPO"
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Clone repository
    if [ -d "$CLIENT_NAME" ]; then
        log_info "Updating existing repository..."
        cd "$CLIENT_NAME"
        git pull origin main
    else
        log_info "Cloning repository..."
        git clone "https://github.com/$CLIENT_REPO.git" "$CLIENT_NAME"
        cd "$CLIENT_NAME"
    fi
    
    # Check if content directory exists
    if [ ! -d "content" ] && [ ! -d "website" ] && [ ! -d "public" ]; then
        log_error "No content directory found. Expected: content/, website/, or public/"
        exit 1
    fi
    
    # Determine content directory
    if [ -d "content" ]; then
        CONTENT_DIR="content"
    elif [ -d "website" ]; then
        CONTENT_DIR="website"
    elif [ -d "public" ]; then
        CONTENT_DIR="public"
    fi
    
    log_success "Repository setup complete. Content directory: $CONTENT_DIR"
    echo "$temp_dir/$CLIENT_NAME/$CONTENT_DIR"
}

# Deploy content to S3
deploy_to_s3() {
    local content_dir="$1"
    
    log_info "Deploying content to S3 bucket: $BUCKET_NAME"
    
    # Sync static assets with long cache
    aws s3 sync "$content_dir/" "s3://$BUCKET_NAME/" \
        --delete \
        --cache-control "public, max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.css" \
        --exclude "*.js" \
        --exclude "*.json"
    
    # Sync HTML/CSS/JS with shorter cache
    aws s3 sync "$content_dir/" "s3://$BUCKET_NAME/" \
        --cache-control "public, max-age=3600" \
        --include "*.html" \
        --include "*.css" \
        --include "*.js" \
        --include "*.json"
    
    # Set proper content types
    aws s3 cp "s3://$BUCKET_NAME/index.html" "s3://$BUCKET_NAME/index.html" \
        --content-type "text/html" --metadata-directive REPLACE 2>/dev/null || true
    
    log_success "Content deployed to S3"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log_info "Invalidating CloudFront cache..."
    
    local invalidation_id
    invalidation_id=$(aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    log_success "CloudFront invalidation created: $invalidation_id"
    
    # Wait for invalidation to complete
    if [ "${WAIT_FOR_INVALIDATION:-false}" = "true" ]; then
        log_info "Waiting for invalidation to complete..."
        aws cloudfront wait invalidation-completed \
            --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --id "$invalidation_id"
        log_success "CloudFront invalidation completed"
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if index.html exists
    if aws s3 ls "s3://$BUCKET_NAME/index.html" &> /dev/null; then
        log_success "index.html found in S3"
    else
        log_warning "index.html not found in S3"
    fi
    
    # Get CloudFront domain
    local cf_domain
    cf_domain=$(aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query 'Distribution.DomainName' --output text)
    
    log_info "Deployment verification complete"
    log_info "CloudFront URL: https://$cf_domain"
}

# Cleanup temporary files
cleanup() {
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$temp_dir"
    fi
}

# Main deployment function
main() {
    log_info "Starting client content deployment for: $CLIENT_NAME"
    log_info "Repository: $CLIENT_REPO"
    log_info "S3 Bucket: $BUCKET_NAME"
    log_info "CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Execute deployment steps
    check_prerequisites
    content_dir=$(setup_client_repo)
    deploy_to_s3 "$content_dir"
    invalidate_cloudfront
    verify_deployment
    
    log_success "Client content deployment completed successfully!"
    log_info "Client: $CLIENT_NAME"
    log_info "Repository: $CLIENT_REPO"
    log_info "S3 Bucket: $BUCKET_NAME"
    log_info "CloudFront Distribution: $CLOUDFRONT_DISTRIBUTION_ID"
}

# Run main function
main "$@"
