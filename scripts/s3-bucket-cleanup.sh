#!/bin/bash

# 🧹 S3 Bucket Cleanup Script
# Removes stale, unused, and temporary files from S3 bucket

set -e

# Configuration
S3_BUCKET="robert-consulting-website"
AWS_REGION="us-east-1"
DRY_RUN=${1:-false}  # Set to true for dry run

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 S3 Bucket Cleanup Script${NC}"
echo "=================================="
echo "Bucket: $S3_BUCKET"
echo "Region: $AWS_REGION"
echo "Dry Run: $DRY_RUN"
echo ""

# Function to log with timestamp
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
    
    log "AWS CLI is configured and working"
}

# Function to get file age in days
get_file_age() {
    local file_date="$1"
    local current_date=$(date +%s)
    local file_timestamp=$(date -d "$file_date" +%s 2>/dev/null || echo "0")
    local age_days=$(( (current_date - file_timestamp) / 86400 ))
    echo $age_days
}

# Function to clean up old backup files
cleanup_backup_files() {
    log "🗑️  Cleaning up old backup files..."
    
    local backup_patterns=("*.bak" "*.backup" "*.old" "*.orig" "*.tmp" "*.temp")
    local files_removed=0
    
    for pattern in "${backup_patterns[@]}"; do
        log "Checking for files matching pattern: $pattern"
        
        # List files matching pattern
        local files=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | grep -E "\.(${pattern#*.})$" | awk '{print $1" "$2" "$4}' || true)
        
        if [ -n "$files" ]; then
            echo "$files" | while read -r line; do
                if [ -n "$line" ]; then
                    local file_date=$(echo "$line" | awk '{print $1" "$2}')
                    local file_path=$(echo "$line" | awk '{print $3}')
                    local age_days=$(get_file_age "$file_date")
                    
                    if [ $age_days -gt 30 ]; then
                        log "Removing old backup file: $file_path (age: ${age_days} days)"
                        if [ "$DRY_RUN" = "false" ]; then
                            aws s3 rm "s3://$S3_BUCKET/$file_path"
                        fi
                        files_removed=$((files_removed + 1))
                    else
                        log "Keeping recent backup file: $file_path (age: ${age_days} days)"
                    fi
                fi
            done
        fi
    done
    
    log "✅ Backup cleanup completed. Files removed: $files_removed"
}

# Function to clean up temporary files
cleanup_temp_files() {
    log "🗑️  Cleaning up temporary files..."
    
    local temp_patterns=("*.tmp" "*.temp" "*.log" "*.cache" "*.lock")
    local files_removed=0
    
    for pattern in "${temp_patterns[@]}"; do
        log "Checking for files matching pattern: $pattern"
        
        # List files matching pattern
        local files=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | grep -E "\.(${pattern#*.})$" | awk '{print $4}' || true)
        
        if [ -n "$files" ]; then
            echo "$files" | while read -r file_path; do
                if [ -n "$file_path" ]; then
                    log "Removing temporary file: $file_path"
                    if [ "$DRY_RUN" = "false" ]; then
                        aws s3 rm "s3://$S3_BUCKET/$file_path"
                    fi
                    files_removed=$((files_removed + 1))
                fi
            done
        fi
    done
    
    log "✅ Temporary files cleanup completed. Files removed: $files_removed"
}

# Function to clean up old log files
cleanup_log_files() {
    log "🗑️  Cleaning up old log files..."
    
    local files_removed=0
    
    # List all log files
    local log_files=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | grep -E "\.log$" | awk '{print $1" "$2" "$4}' || true)
    
    if [ -n "$log_files" ]; then
        echo "$log_files" | while read -r line; do
            if [ -n "$line" ]; then
                local file_date=$(echo "$line" | awk '{print $1" "$2}')
                local file_path=$(echo "$line" | awk '{print $3}')
                local age_days=$(get_file_age "$file_date")
                
                if [ $age_days -gt 7 ]; then
                    log "Removing old log file: $file_path (age: ${age_days} days)"
                    if [ "$DRY_RUN" = "false" ]; then
                        aws s3 rm "s3://$S3_BUCKET/$file_path"
                    fi
                    files_removed=$((files_removed + 1))
                else
                    log "Keeping recent log file: $file_path (age: ${age_days} days)"
                fi
            fi
        done
    fi
    
    log "✅ Log files cleanup completed. Files removed: $files_removed"
}

# Function to clean up duplicate files
cleanup_duplicate_files() {
    log "🗑️  Cleaning up duplicate files..."
    
    local files_removed=0
    
    # Find files with duplicate names (excluding versioned files)
    local duplicate_files=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | awk '{print $4}' | sort | uniq -d || true)
    
    if [ -n "$duplicate_files" ]; then
        echo "$duplicate_files" | while read -r file_path; do
            if [ -n "$file_path" ]; then
                # Get all versions of this file
                local versions=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | grep "$file_path" | awk '{print $1" "$2" "$4}' | sort -r || true)
                
                # Keep the most recent version, remove others
                local first=true
                echo "$versions" | while read -r line; do
                    if [ -n "$line" ]; then
                        local file_date=$(echo "$line" | awk '{print $1" "$2}')
                        local full_path=$(echo "$line" | awk '{print $3}')
                        
                        if [ "$first" = "true" ]; then
                            log "Keeping most recent version: $full_path"
                            first=false
                        else
                            log "Removing older version: $full_path"
                            if [ "$DRY_RUN" = "false" ]; then
                                aws s3 rm "s3://$S3_BUCKET/$full_path"
                            fi
                            files_removed=$((files_removed + 1))
                        fi
                    fi
                done
            fi
        done
    fi
    
    log "✅ Duplicate files cleanup completed. Files removed: $files_removed"
}

# Function to clean up empty directories
cleanup_empty_directories() {
    log "🗑️  Cleaning up empty directories..."
    
    local dirs_removed=0
    
    # Find empty directories (directories with no files)
    local directories=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | awk '{print $4}' | sed 's/[^/]*$//' | sort | uniq || true)
    
    if [ -n "$directories" ]; then
        echo "$directories" | while read -r dir_path; do
            if [ -n "$dir_path" ] && [ "$dir_path" != "" ]; then
                # Check if directory has any files
                local files_in_dir=$(aws s3 ls "s3://$S3_BUCKET/$dir_path" --recursive | wc -l || echo "0")
                
                if [ "$files_in_dir" -eq 0 ]; then
                    log "Removing empty directory: $dir_path"
                    if [ "$DRY_RUN" = "false" ]; then
                        aws s3 rm "s3://$S3_BUCKET/$dir_path" --recursive
                    fi
                    dirs_removed=$((dirs_removed + 1))
                fi
            fi
        done
    fi
    
    log "✅ Empty directories cleanup completed. Directories removed: $dirs_removed"
}

# Function to generate cleanup report
generate_report() {
    log "📊 Generating cleanup report..."
    
    local total_files=$(aws s3 ls "s3://$S3_BUCKET/" --recursive | wc -l || echo "0")
    local total_size=$(aws s3 ls "s3://$S3_BUCKET/" --recursive --summarize | grep "Total Size" | awk '{print $3}' || echo "0")
    
    echo ""
    echo "=================================="
    echo "🧹 S3 Bucket Cleanup Report"
    echo "=================================="
    echo "Bucket: $S3_BUCKET"
    echo "Total Files: $total_files"
    echo "Total Size: $total_size bytes"
    echo "Cleanup Date: $(date)"
    echo "Dry Run: $DRY_RUN"
    echo "=================================="
}

# Main execution
main() {
    log "Starting S3 bucket cleanup..."
    
    # Check prerequisites
    check_aws_cli
    
    # Run cleanup operations
    cleanup_backup_files
    cleanup_temp_files
    cleanup_log_files
    cleanup_duplicate_files
    cleanup_empty_directories
    
    # Generate report
    generate_report
    
    log "✅ S3 bucket cleanup completed successfully!"
}

# Run main function
main "$@"
