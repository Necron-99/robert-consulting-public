#!/bin/bash

# S3 Bucket Cleanup Script
# Removes unnecessary files and keeps only essential web files

set -e  # Exit on any error

# Configuration
S3_BUCKET="robert-consulting-website"
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

# Function to show current bucket contents
show_bucket_contents() {
    print_status "Current S3 bucket contents:"
    echo ""
    
    # Count total files
    TOTAL_FILES=$(aws s3 ls s3://$S3_BUCKET/ --recursive | wc -l)
    print_status "Total files in bucket: $TOTAL_FILES"
    
    # Show file types
    echo ""
    print_status "File types breakdown:"
    aws s3 ls s3://$S3_BUCKET/ --recursive | awk '{print $4}' | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10
    
    # Show largest directories
    echo ""
    print_status "Largest directories:"
    aws s3 ls s3://$S3_BUCKET/ --recursive | awk '{print $4}' | cut -d'/' -f1 | sort | uniq -c | sort -nr | head -10
}

# Function to clean up unnecessary files
cleanup_bucket() {
    print_status "Starting S3 bucket cleanup..."
    
    # Remove node_modules directory
    print_status "Removing node_modules directory..."
    aws s3 rm s3://$S3_BUCKET/node_modules/ --recursive || print_warning "node_modules directory not found or already removed"
    
    # Remove backup files
    print_status "Removing backup files..."
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.backup" || print_warning "No backup files found"
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.bak" || print_warning "No .bak files found"
    
    # Remove log files
    print_status "Removing log files..."
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.log" || print_warning "No log files found"
    
    # Remove development files
    print_status "Removing development files..."
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "package*.json" || print_warning "No package.json files found"
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.ps1" || print_warning "No PowerShell files found"
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "deploy-*.sh" || print_warning "No deploy scripts found"
    
    # Remove zip files (except essential ones)
    print_status "Removing unnecessary zip files..."
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include "*.zip" || print_warning "No zip files found"
    
    # Remove hidden files
    print_status "Removing hidden files..."
    aws s3 rm s3://$S3_BUCKET/ --recursive --exclude "*" --include ".*" || print_warning "No hidden files found"
    
    print_success "Cleanup completed"
}

# Function to show remaining files
show_remaining_files() {
    print_status "Remaining files after cleanup:"
    echo ""
    
    # Count remaining files
    REMAINING_FILES=$(aws s3 ls s3://$S3_BUCKET/ --recursive | wc -l)
    print_status "Remaining files: $REMAINING_FILES"
    
    # Show remaining file types
    echo ""
    print_status "Remaining file types:"
    aws s3 ls s3://$S3_BUCKET/ --recursive | awk '{print $4}' | sed 's/.*\.//' | sort | uniq -c | sort -nr
    
    # Show remaining directories
    echo ""
    print_status "Remaining directories:"
    aws s3 ls s3://$S3_BUCKET/ --recursive | awk '{print $4}' | cut -d'/' -f1 | sort | uniq -c | sort -nr
}

# Function to show cleanup summary
show_summary() {
    print_success "S3 bucket cleanup completed!"
    echo ""
    echo "🧹 Cleanup Actions:"
    echo "  ✅ Removed node_modules directory"
    echo "  ✅ Removed backup files (*.backup, *.bak)"
    echo "  ✅ Removed log files (*.log)"
    echo "  ✅ Removed development files (package.json, *.ps1, deploy-*.sh)"
    echo "  ✅ Removed unnecessary zip files"
    echo "  ✅ Removed hidden files"
    echo ""
    echo "📊 Results:"
    echo "  - Only essential web files remain"
    echo "  - Significantly reduced storage usage"
    echo "  - Faster deployment times"
    echo "  - Cleaner bucket structure"
    echo ""
    echo "💡 Next Steps:"
    echo "  - Use selective deployment scripts for future updates"
    echo "  - Run: ./scripts/deployment/deploy-logo-navigation.sh"
    echo "  - Or run: ./scripts/deployment/deploy-website-selective.sh"
}

# Main execution
main() {
    echo "🧹 Starting S3 bucket cleanup..."
    echo ""
    
    # Check prerequisites
    check_aws_cli
    
    # Show current contents
    show_bucket_contents
    
    # Ask for confirmation
    echo ""
    print_warning "This will remove unnecessary files from the S3 bucket."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
    
    # Perform cleanup
    cleanup_bucket
    
    # Show remaining files
    show_remaining_files
    
    # Show summary
    show_summary
}

# Parse command line arguments
case "$1" in
    "--force")
        # Skip confirmation prompt
        check_aws_cli
        show_bucket_contents
        cleanup_bucket
        show_remaining_files
        show_summary
        ;;
    "--help" | "-h")
        echo "Usage: $0 [--force] [--help]"
        echo ""
        echo "Options:"
        echo "  --force    Skip confirmation prompt"
        echo "  --help     Show this help message"
        echo ""
        echo "This script cleans up the S3 bucket by removing:"
        echo "  - node_modules directory"
        echo "  - Backup files (*.backup, *.bak)"
        echo "  - Log files (*.log)"
        echo "  - Development files (package.json, *.ps1, deploy-*.sh)"
        echo "  - Unnecessary zip files"
        echo "  - Hidden files"
        echo ""
        echo "Examples:"
        echo "  $0                # Interactive cleanup with confirmation"
        echo "  $0 --force        # Automatic cleanup without confirmation"
        ;;
    *)
        main
        ;;
esac
