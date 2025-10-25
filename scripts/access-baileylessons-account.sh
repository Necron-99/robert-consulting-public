#!/bin/bash

# Bailey Lessons Account Access Script
# This script helps access the baileylessons AWS account (737915157697)

set -e

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

# Bailey Lessons account configuration
BAILEYLESSONS_ACCOUNT_ID="737915157697"
ROLE_NAME="OrganizationAccountAccessRole"
ROLE_ARN="arn:aws:iam::${BAILEYLESSONS_ACCOUNT_ID}:role/${ROLE_NAME}"

# Function to assume role into baileylessons account
assume_baileylessons_role() {
    print_status "Assuming role into Bailey Lessons account (${BAILEYLESSONS_ACCOUNT_ID})..."
    
    # Create unique session name
    SESSION_NAME="baileylessons-access-$(date +%s)"
    
    # Assume the role
    CREDENTIALS=$(aws sts assume-role \
        --role-arn "$ROLE_ARN" \
        --role-session-name "$SESSION_NAME" \
        --query 'Credentials' --output json)
    
    if [ $? -eq 0 ]; then
        # Extract credentials
        ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
        SECRET_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
        SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.SessionToken')
        
        # Set environment variables
        export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
        export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
        export AWS_SESSION_TOKEN="$SESSION_TOKEN"
        
        print_success "Successfully assumed role into Bailey Lessons account"
        
        # Verify access
        CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
        if [ "$CURRENT_ACCOUNT" = "$BAILEYLESSONS_ACCOUNT_ID" ]; then
            print_success "Verified access to Bailey Lessons account (${BAILEYLESSONS_ACCOUNT_ID})"
            return 0
        else
            print_error "Failed to verify access to Bailey Lessons account"
            return 1
        fi
    else
        print_error "Failed to assume role into Bailey Lessons account"
        return 1
    fi
}

# Function to discover baileylessons resources
discover_resources() {
    print_status "Discovering Bailey Lessons resources..."
    
    echo ""
    print_status "S3 Buckets:"
    aws s3 ls 2>/dev/null || print_warning "No S3 access or buckets found"
    
    echo ""
    print_status "CloudFront Distributions:"
    aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,DomainName:DomainName,Comment:Comment,Status:Status}' --output table 2>/dev/null || print_warning "No CloudFront access or distributions found"
    
    echo ""
    print_status "Route53 Hosted Zones:"
    aws route53 list-hosted-zones --query 'HostedZones[].{Id:Id,Name:Name,ResourceRecordSetCount:ResourceRecordSetCount}' --output table 2>/dev/null || print_warning "No Route53 access or zones found"
    
    echo ""
    print_status "Lambda Functions:"
    aws lambda list-functions --query 'Functions[].{Name:FunctionName,Runtime:Runtime,LastModified:LastModified}' --output table 2>/dev/null || print_warning "No Lambda access or functions found"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  assume                   - Assume role into Bailey Lessons account"
    echo "  discover                 - Discover existing resources"
    echo "  shell                    - Start shell with Bailey Lessons credentials"
    echo "  exec <command>          - Execute command in Bailey Lessons context"
    echo ""
    echo "Examples:"
    echo "  $0 assume"
    echo "  $0 discover"
    echo "  $0 shell"
    echo "  $0 exec 'aws s3 ls'"
}

# Main script logic
case "$1" in
    "assume")
        assume_baileylessons_role
        ;;
    "discover")
        assume_baileylessons_role
        if [ $? -eq 0 ]; then
            discover_resources
        fi
        ;;
    "shell")
        assume_baileylessons_role
        if [ $? -eq 0 ]; then
            print_success "Starting shell with Bailey Lessons credentials..."
            print_warning "Type 'exit' to return to management account"
            exec bash
        fi
        ;;
    "exec")
        if [ -z "$2" ]; then
            print_error "Please specify a command to execute"
            show_usage
            exit 1
        fi
        
        assume_baileylessons_role
        if [ $? -eq 0 ]; then
            print_success "Executing command in Bailey Lessons context..."
            eval "$2"
        fi
        ;;
    *)
        show_usage
        ;;
esac
