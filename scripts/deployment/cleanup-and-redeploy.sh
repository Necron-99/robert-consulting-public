#!/bin/bash

# Complete S3 Bucket Cleanup and Redeploy
# Empties bucket completely and redeploys only essential files

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

# Function to completely empty the S3 bucket
empty_bucket() {
    print_status "Completely emptying S3 bucket: $S3_BUCKET"
    
    # Show current file count
    CURRENT_FILES=$(aws s3 ls s3://$S3_BUCKET/ --recursive | wc -l)
    print_status "Current files in bucket: $CURRENT_FILES"
    
    if [ $CURRENT_FILES -eq 0 ]; then
        print_warning "Bucket is already empty"
        return
    fi
    
    # Remove all files
    print_status "Removing all files from bucket..."
    aws s3 rm s3://$S3_BUCKET/ --recursive
    
    print_success "Bucket completely emptied"
}

# Function to create a temporary directory with only web files
prepare_web_files() {
    print_status "Preparing essential web files for deployment..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    print_status "Using temporary directory: $TEMP_DIR"
    
    # Copy only essential web files
    print_status "Copying HTML files..."
    find website/ -name "*.html" -not -path "*/node_modules/*" -not -name "*.backup" -exec cp --parents {} $TEMP_DIR/ \;
    
    print_status "Copying CSS files..."
    find website/ -name "*.css" -not -path "*/node_modules/*" -exec cp --parents {} $TEMP_DIR/ \;
    
    print_status "Copying JavaScript files..."
    find website/ -name "*.js" -not -path "*/node_modules/*" -not -name "*.backup" -exec cp --parents {} $TEMP_DIR/ \;
    
    print_status "Copying image files..."
    find website/ -name "*.svg" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.ico" -not -path "*/node_modules/*" -exec cp --parents {} $TEMP_DIR/ \;
    
    print_status "Copying other essential files..."
    find website/ -name "*.json" -not -path "*/node_modules/*" -not -name "package*.json" -exec cp --parents {} $TEMP_DIR/ \;
    
    # Copy .deployignore if it exists
    if [ -f "website/.deployignore" ]; then
        cp website/.deployignore $TEMP_DIR/
    fi
    
    # Show what we're deploying
    WEB_FILES_COUNT=$(find $TEMP_DIR -type f | wc -l)
    print_success "Prepared $WEB_FILES_COUNT essential web files for deployment"
    
    # Show file count by type
    HTML_COUNT=$(find $TEMP_DIR -name "*.html" | wc -l)
    CSS_COUNT=$(find $TEMP_DIR -name "*.css" | wc -l)
    JS_COUNT=$(find $TEMP_DIR -name "*.js" | wc -l)
    IMG_COUNT=$(find $TEMP_DIR -name "*.svg" -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.ico" | wc -l)
    
    echo "  📄 HTML files: $HTML_COUNT"
    echo "  🎨 CSS files: $CSS_COUNT"
    echo "  ⚡ JavaScript files: $JS_COUNT"
    echo "  🖼️  Image files: $IMG_COUNT"
}

# Function to deploy files to S3
deploy_to_s3() {
    print_status "Deploying essential web files to S3 bucket: $S3_BUCKET"
    
    if aws s3 sync $TEMP_DIR/ s3://$S3_BUCKET/; then
        print_success "Essential web files deployed to S3 successfully"
    else
        print_error "Failed to deploy files to S3"
        exit 1
    fi
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

# Function to cleanup temporary directory
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_status "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
        print_success "Cleanup completed"
    fi
}

# Function to show deployment summary
show_summary() {
    print_success "Complete cleanup and redeploy completed successfully!"
    echo ""
    echo "🧹 Cleanup Actions:"
    echo "  ✅ Completely emptied S3 bucket"
    echo "  ✅ Removed all unnecessary files"
    echo ""
    echo "🚀 Deployment Actions:"
    echo "  ✅ Deployed only essential web files"
    echo "  ✅ Excluded node_modules and development files"
    echo "  ✅ Invalidated CloudFront cache"
    echo ""
    echo "🌐 Website URLs:"
    echo "  Main Site: https://robertconsulting.net/index.html"
    echo "  Learning: https://robertconsulting.net/learning.html"
    echo "  Stats: https://robertconsulting.net/stats.html"
    echo "  Dashboard: https://robertconsulting.net/dashboard.html"
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
    echo "✅ Bucket is now clean with only essential files!"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    echo "🧹🚀 Starting complete S3 cleanup and redeploy..."
    echo ""
    
    # Check prerequisites
    check_aws_cli
    
    # Empty bucket completely
    empty_bucket
    
    # Prepare web files
    prepare_web_files
    
    # Deploy files
    deploy_to_s3
    
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
        echo "This script performs a complete cleanup and redeploy:"
        echo "  1. Completely empties the S3 bucket"
        echo "  2. Deploys only essential web files"
        echo "  3. Excludes node_modules and development files"
        echo "  4. Invalidates CloudFront cache"
        echo ""
        echo "Examples:"
        echo "  $0                # Cleanup and redeploy"
        echo "  $0 --wait         # Cleanup, redeploy, and wait for completion"
        ;;
    *)
        main
        ;;
esac
