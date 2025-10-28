#!/bin/bash

# Bailey Lessons S3 Content Sync Script
# This script downloads content from S3 buckets to local storage

set -euo pipefail

# Configuration
AWS_REGION="us-east-1"
S3_STATIC_BUCKET="baileylessons-production-static"
S3_UPLOADS_BUCKET="baileylessons-production-uploads"
S3_BACKUPS_BUCKET="baileylessons-production-backups"
S3_LOGS_BUCKET="baileylessons-production-logs"

# Local directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
S3_CONTENT_DIR="$PROJECT_ROOT/baileylessons/s3-content"

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
}

# Sync S3 bucket to local directory
sync_bucket() {
    local bucket_name="$1"
    local local_dir="$2"
    local description="$3"
    
    log_info "Syncing $description from $bucket_name..."
    
    if aws s3 ls "s3://$bucket_name" &> /dev/null; then
        mkdir -p "$local_dir"
        aws s3 sync "s3://$bucket_name/" "$local_dir/" \
            --region "$AWS_REGION" \
            --exclude "*.tmp" \
            --exclude "*.temp" \
            --exclude "*.log" \
            --exclude "*.bak" \
            --exclude "*.backup"
        log_success "Synced $description"
    else
        log_warning "Bucket $bucket_name does not exist or is not accessible"
    fi
}

# Main sync function
sync_all_content() {
    log_info "Starting S3 content sync for Bailey Lessons..."
    
    # Check prerequisites
    check_aws_cli
    check_aws_credentials
    
    # Create S3 content directory
    mkdir -p "$S3_CONTENT_DIR"
    
    # Sync each bucket
    sync_bucket "$S3_STATIC_BUCKET" "$S3_CONTENT_DIR/static" "static website files"
    sync_bucket "$S3_UPLOADS_BUCKET" "$S3_CONTENT_DIR/uploads" "user uploads"
    sync_bucket "$S3_BACKUPS_BUCKET" "$S3_CONTENT_DIR/backups" "backup files"
    sync_bucket "$S3_LOGS_BUCKET" "$S3_CONTENT_DIR/logs" "log files"
    
    log_success "S3 content sync completed!"
    
    # Show summary
    echo ""
    log_info "Content summary:"
    find "$S3_CONTENT_DIR" -type f | wc -l | xargs -I {} echo "  Total files: {}"
    du -sh "$S3_CONTENT_DIR" | cut -f1 | xargs -I {} echo "  Total size: {}"
}

# Upload local content to S3
upload_content() {
    local local_dir="$1"
    local bucket_name="$2"
    local description="$3"
    
    log_info "Uploading $description to $bucket_name..."
    
    if [ -d "$local_dir" ] && [ "$(ls -A "$local_dir")" ]; then
        aws s3 sync "$local_dir/" "s3://$bucket_name/" \
            --region "$AWS_REGION" \
            --exclude "*.tmp" \
            --exclude "*.temp" \
            --exclude "*.log" \
            --exclude "*.bak" \
            --exclude "*.backup"
        log_success "Uploaded $description"
    else
        log_warning "No content found in $local_dir"
    fi
}

# Upload all content to S3
upload_all_content() {
    log_info "Starting upload to S3 buckets..."
    
    check_aws_cli
    check_aws_credentials
    
    upload_content "$S3_CONTENT_DIR/static" "$S3_STATIC_BUCKET" "static website files"
    upload_content "$S3_CONTENT_DIR/uploads" "$S3_UPLOADS_BUCKET" "user uploads"
    upload_content "$S3_CONTENT_DIR/backups" "$S3_BACKUPS_BUCKET" "backup files"
    upload_content "$S3_CONTENT_DIR/logs" "$S3_LOGS_BUCKET" "log files"
    
    log_success "Upload completed!"
}

# Show usage
show_usage() {
    echo "Bailey Lessons S3 Content Sync Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  sync     Download content from S3 to local storage (default)"
    echo "  upload   Upload local content to S3 buckets"
    echo "  help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 sync      # Download from S3"
    echo "  $0 upload    # Upload to S3"
}

# Main script logic
main() {
    local command="${1:-sync}"
    
    case "$command" in
        "sync")
            sync_all_content
            ;;
        "upload")
            upload_all_content
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
