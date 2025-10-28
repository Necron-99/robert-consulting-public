#!/bin/bash

# Bailey Lessons Deployment Script
# Deploys baileylessons content to staging or production

set -euo pipefail

# Configuration
AWS_REGION="us-east-1"
STAGING_BUCKET="baileylessons-staging-static"
PRODUCTION_BUCKET="baileylessons-production-static"
CLOUDFRONT_DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID:-}"

# Local directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
WEBSITE_DIR="$PROJECT_ROOT/baileylessons/website"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    if [ ! -d "$WEBSITE_DIR" ]; then
        log_error "Website directory not found: $WEBSITE_DIR"
        exit 1
    fi
}

# Deploy to S3 with whitelist approach
deploy_to_s3() {
    local bucket_name="$1"
    local environment="$2"
    
    log_info "Deploying to $environment ($bucket_name)..."
    
    # Deploy website files with whitelist approach
    aws s3 sync "$WEBSITE_DIR" "s3://$bucket_name/" \
        --delete \
        --exclude "*" \
        --include "**/*.html" \
        --include "**/*.css" \
        --include "**/*.js" \
        --include "**/*.png" \
        --include "**/*.jpg" \
        --include "**/*.jpeg" \
        --include "**/*.gif" \
        --include "**/*.webp" \
        --include "**/*.svg" \
        --include "**/*.ico" \
        --include "**/*.woff" \
        --include "**/*.woff2" \
        --include "**/*.ttf" \
        --include "**/*.otf" \
        --include "**/*.eot" \
        --include "**/sitemap.xml" \
        --include "**/robots.txt" \
        --include "**/manifest.json" \
        --exclude "blog-posts/*" \
        --region "$AWS_REGION"
    
    # Deploy blog posts separately (preserve existing)
    if [ -d "$WEBSITE_DIR/blog-posts" ]; then
        aws s3 sync "$WEBSITE_DIR/blog-posts" "s3://$bucket_name/blog-posts/" \
            --exclude "**/.DS_Store" \
            --region "$AWS_REGION"
    fi
    
    log_success "Deployed to $environment"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
        log_info "Invalidating CloudFront cache..."
        aws cloudfront create-invalidation \
            --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --paths "/*" \
            --region "$AWS_REGION"
        log_success "CloudFront cache invalidated"
    else
        log_warning "CLOUDFRONT_DISTRIBUTION_ID not set - skipping cache invalidation"
    fi
}

# Deploy to staging
deploy_staging() {
    log_info "Deploying to staging environment..."
    check_prerequisites
    deploy_to_s3 "$STAGING_BUCKET" "staging"
    log_success "Staging deployment completed!"
}

# Deploy to production
deploy_production() {
    log_info "Deploying to production environment..."
    check_prerequisites
    deploy_to_s3 "$PRODUCTION_BUCKET" "production"
    invalidate_cloudfront
    log_success "Production deployment completed!"
}

# Show usage
show_usage() {
    echo "Bailey Lessons Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  staging     Deploy to staging environment"
    echo "  production  Deploy to production environment"
    echo "  help        Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  CLOUDFRONT_DISTRIBUTION_ID  CloudFront distribution ID for cache invalidation"
    echo ""
    echo "Examples:"
    echo "  $0 staging      # Deploy to staging"
    echo "  $0 production   # Deploy to production"
    echo "  CLOUDFRONT_DISTRIBUTION_ID=ABC123 $0 production"
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "staging")
            deploy_staging
            ;;
        "production")
            deploy_production
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
