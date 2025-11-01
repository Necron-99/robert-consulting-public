#!/bin/bash

# Deploy Only Logo and Navigation Changes
# Minimal deployment for specific updates

set -e  # Exit on any error

# Configuration
S3_BUCKET="robert-consulting-website"
DISTRIBUTION_ID="E36DBYPHUUKB3V"
AWS_REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi

    print_success "AWS CLI is configured"
}

# Function to deploy specific files
deploy_specific_files() {
    print_status "Deploying logo and navigation changes to S3 bucket: $S3_BUCKET"
    
    # Deploy logo files
    print_status "Deploying logo files..."
    aws s3 cp website/images/robert-consulting-logo.svg s3://$S3_BUCKET/images/robert-consulting-logo.svg
    aws s3 cp website/images/README.md s3://$S3_BUCKET/images/README.md
    
    # Deploy CSS files
    print_status "Deploying CSS files..."
    aws s3 cp website/css/components/logo.css s3://$S3_BUCKET/css/components/logo.css
    aws s3 cp website/css/components/navigation.css s3://$S3_BUCKET/css/components/navigation.css
    aws s3 cp website/css/variables.css s3://$S3_BUCKET/css/variables.css
    aws s3 cp website/css/main.css s3://$S3_BUCKET/css/main.css
    
    # Deploy JavaScript files
    print_status "Deploying JavaScript files..."
    aws s3 cp website/js/logo-watermark.js s3://$S3_BUCKET/js/logo-watermark.js
    
    # Deploy HTML files (in case they were updated)
    print_status "Deploying HTML files..."
    aws s3 cp website/index.html s3://$S3_BUCKET/index.html
    
    print_success "Specific files deployed to S3 successfully"
}

# Function to invalidate CloudFront cache
invalidate_cloudfront() {
    print_status "Invalidating CloudFront cache for distribution: $DISTRIBUTION_ID"
    
    # Create invalidation
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    if [ $? -eq 0 ]; then
        print_success "CloudFront invalidation created: $INVALIDATION_ID"
        print_status "Cache invalidation is in progress..."
        print_warning "It may take 5-15 minutes for changes to be visible globally"
        
        # Optional: Wait and check status
        if [ "$1" = "--wait" ]; then
            wait_for_invalidation $INVALIDATION_ID
        fi
    else
        print_error "Failed to create CloudFront invalidation"
        exit 1
    fi
}

# Function to wait for invalidation completion
wait_for_invalidation() {
    local invalidation_id=$1
    print_status "Waiting for invalidation to complete..."
    
    while true; do
        STATUS=$(aws cloudfront get-invalidation \
            --distribution-id $DISTRIBUTION_ID \
            --id $invalidation_id \
            --query 'Invalidation.Status' \
            --output text)
        
        case $STATUS in
            "Completed")
                print_success "Cache invalidation completed!"
                break
                ;;
            "InProgress")
                print_status "Invalidation in progress... (Status: $STATUS)"
                sleep 30
                ;;
            *)
                print_warning "Invalidation status: $STATUS"
                sleep 30
                ;;
        esac
    done
}

# Function to show deployment summary
show_summary() {
    print_success "Logo and navigation deployment completed successfully!"
    echo ""
    echo "🎨 Deployed Files:"
    echo "  📄 website/images/robert-consulting-logo.svg"
    echo "  📄 website/css/components/logo.css"
    echo "  📄 website/css/components/navigation.css"
    echo "  📄 website/css/variables.css"
    echo "  📄 website/css/main.css"
    echo "  📄 website/js/logo-watermark.js"
    echo "  📄 website/index.html"
    echo ""
    echo "🌐 Website URLs:"
    echo "  Main Site: https://robertconsulting.net/index.html"
    echo ""
    echo "📊 CloudFront Distribution:"
    echo "  Domain: d24d7iql53878z.cloudfront.net"
    echo "  Status: Cache invalidation in progress"
    echo ""
    echo "💡 Tips:"
    echo "  - Use Ctrl+F5 or Cmd+Shift+R to force refresh"
    echo "  - Try incognito/private mode if changes aren't visible"
    echo "  - Changes may take 5-15 minutes to appear globally"
    echo ""
    echo "✅ Only logo and navigation files were deployed (minimal deployment)"
}

# Main execution
main() {
    echo "🎨 Starting logo and navigation deployment..."
    echo ""
    
    # Check prerequisites
    check_aws_cli
    
    # Deploy specific files
    deploy_specific_files
    
    # Invalidate cache
    invalidate_cloudfront "$1"
    
    # Show summary
    show_summary
}

# Parse command line arguments
case "$1" in
    "--wait")
        main "--wait"
        ;;
    "--help" | "-h")
        echo "Usage: $0 [--wait] [--help]"
        echo ""
        echo "Options:"
        echo "  --wait    Wait for CloudFront invalidation to complete"
        echo "  --help    Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                # Deploy and invalidate cache"
        echo "  $0 --wait         # Deploy and wait for completion"
        echo ""
        echo "This script only deploys logo and navigation related files:"
        echo "  - Logo SVG and CSS files"
        echo "  - Navigation CSS files"
        echo "  - Updated HTML files"
        echo "  - Minimal deployment for specific changes"
        ;;
    *)
        main
        ;;
esac
