#!/bin/bash

# Testing Site Cleanup Script
# Safely remove all testing site resources to avoid ongoing costs

set -e

# Configuration
TESTING_BUCKET=""
DISTRIBUTION_ID=""
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Get testing site resources
get_testing_resources() {
    log_info "Finding testing site resources..."
    
    # Find S3 buckets with testing tag
    TESTING_BUCKET=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `robert-consulting-testing`)].Name' --output text | head -1)
    
    if [ -z "$TESTING_BUCKET" ]; then
        log_warning "No testing S3 bucket found"
    else
        log_info "Found testing bucket: $TESTING_BUCKET"
    fi
    
    # Find CloudFront distributions
    DISTRIBUTION_ID=$(aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`Testing Site Distribution`].Id' --output text | head -1)
    
    if [ -z "$DISTRIBUTION_ID" ]; then
        log_warning "No testing CloudFront distribution found"
    else
        log_info "Found CloudFront distribution: $DISTRIBUTION_ID"
    fi
}

# Clean up S3 bucket
cleanup_s3_bucket() {
    if [ -z "$TESTING_BUCKET" ]; then
        log_warning "No S3 bucket to clean up"
        return
    fi
    
    log_info "Cleaning up S3 bucket: $TESTING_BUCKET"
    
    # Delete all objects in bucket
    aws s3 rm s3://$TESTING_BUCKET --recursive
    
    # Delete bucket
    aws s3api delete-bucket --bucket $TESTING_BUCKET
    
    log_success "S3 bucket deleted: $TESTING_BUCKET"
}

# Clean up CloudFront distribution
cleanup_cloudfront() {
    if [ -z "$DISTRIBUTION_ID" ]; then
        log_warning "No CloudFront distribution to clean up"
        return
    fi
    
    log_info "Cleaning up CloudFront distribution: $DISTRIBUTION_ID"
    
    # Disable distribution first
    aws cloudfront get-distribution-config --id $DISTRIBUTION_ID > dist-config.json
    jq '.DistributionConfig.Enabled = false' dist-config.json > dist-config-disabled.json
    
    aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://dist-config-disabled.json
    
    # Wait for distribution to be disabled
    log_info "Waiting for CloudFront distribution to be disabled..."
    aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID
    
    # Delete distribution
    aws cloudfront delete-distribution --id $DISTRIBUTION_ID --if-match $(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'ETag' --output text)
    
    # Clean up temp files
    rm -f dist-config.json dist-config-disabled.json
    
    log_success "CloudFront distribution deleted: $DISTRIBUTION_ID"
}

# Clean up Route 53 records (if any)
cleanup_route53() {
    log_info "Checking for Route 53 records..."
    
    # This would need to be customized based on your domain setup
    log_warning "Route 53 cleanup not implemented. Please manually remove any testing domain records."
}

# Clean up budgets
cleanup_budgets() {
    log_info "Cleaning up budgets..."
    
    # List budgets
    BUDGETS=$(aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text) --query 'Budgets[?BudgetName==`testing-site-budget`].BudgetName' --output text)
    
    if [ -n "$BUDGETS" ]; then
        log_info "Found testing budgets: $BUDGETS"
        log_warning "Please manually delete budgets in AWS Console:"
        echo "  - testing-site-budget"
    else
        log_info "No testing budgets found"
    fi
}

# Display cleanup summary
display_cleanup_summary() {
    log_success "Testing site cleanup completed!"
    echo ""
    echo "🧹 Cleanup Summary:"
    echo "  S3 Bucket: $([ -n "$TESTING_BUCKET" ] && echo "Deleted: $TESTING_BUCKET" || echo "Not found")
    echo "  CloudFront: $([ -n "$DISTRIBUTION_ID" ] && echo "Deleted: $DISTRIBUTION_ID" || echo "Not found")
    echo ""
    echo "💰 Cost Impact:"
    echo "  S3 Storage: $0.00/month (deleted)"
    echo "  CloudFront: $0.00/month (deleted)"
    echo "  Total Savings: ~$1.50/month"
    echo ""
    echo "⚠️  Manual Cleanup Required:"
    echo "  - Delete any Route 53 records for testing domains"
    echo "  - Delete testing budgets in AWS Console"
    echo "  - Remove any IAM policies created for testing"
    echo ""
    echo "✅ Testing site resources have been cleaned up successfully!"
}

# Confirmation prompt
confirm_cleanup() {
    echo ""
    log_warning "This will permanently delete all testing site resources:"
    echo "  - S3 bucket and all files"
    echo "  - CloudFront distribution"
    echo "  - Associated costs will stop"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

# Main cleanup process
main() {
    log_info "Starting testing site cleanup..."
    
    confirm_cleanup
    get_testing_resources
    cleanup_s3_bucket
    cleanup_cloudfront
    cleanup_route53
    cleanup_budgets
    display_cleanup_summary
    
    log_success "Testing site cleanup completed successfully!"
}

# Run main function
main "$@"
