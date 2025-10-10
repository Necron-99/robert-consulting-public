#!/bin/bash

# Reset Admin Site Credentials Script
# This script helps reset the admin site basic auth credentials

set -e

# Configuration
ADMIN_USERNAME="${1:-admin}"
ADMIN_PASSWORD="${2:-demo_password_123}"
ADMIN_DISTRIBUTION_ID="E1JE597A8ZZ547"  # From the CloudFront list

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
    echo "Usage: $0 [username] [password]"
    echo ""
    echo "Parameters:"
    echo "  username  - Admin username (default: admin)"
    echo "  password  - Admin password (default: demo_password_123)"
    echo ""
    echo "Example:"
    echo "  $0 admin mynewpassword"
    echo "  $0  # Uses defaults: admin/demo_password_123"
    exit 1
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
    
    log_success "Prerequisites check passed"
}

# Generate base64 encoded credentials
generate_auth_string() {
    local username="$1"
    local password="$2"
    echo -n "${username}:${password}" | base64
}

# Update CloudFront function
update_cloudfront_function() {
    log_info "Updating CloudFront function with new credentials..."
    
    # Generate the new auth string
    local auth_string
    auth_string=$(generate_auth_string "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
    
    # Create the new function code
    local function_code
    function_code=$(cat << EOF
function handler(event) {
  var req = event.request;
  var headers = req.headers;

  var authHeader = headers.authorization && headers.authorization.value;
  var expected = 'Basic ${auth_string}';

  if (!authHeader || authHeader !== expected) {
    return {
      statusCode: 401,
      statusDescription: 'Unauthorized',
      headers: { 'www-authenticate': { value: 'Basic realm="Admin"' } },
      body: 'Authentication required'
    };
  }
  return req;
}
EOF
)
    
    # Find the CloudFront function name
    local function_name
    function_name=$(aws cloudfront list-functions --query 'FunctionList.Items[?contains(Name, `admin`) && contains(Name, `basic-auth`)].Name' --output text)
    
    if [ -z "$function_name" ]; then
        log_error "Could not find admin basic auth CloudFront function"
        exit 1
    fi
    
    log_info "Found CloudFront function: $function_name"
    
    # Update the function
    aws cloudfront update-function \
        --name "$function_name" \
        --function-code "$function_code" \
        --if-match "$(aws cloudfront describe-function --name "$function_name" --query 'ETag' --output text)"
    
    # Publish the function
    aws cloudfront publish-function --name "$function_name" --if-match "$(aws cloudfront describe-function --name "$function_name" --query 'ETag' --output text)"
    
    log_success "CloudFront function updated and published"
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log_info "Invalidating CloudFront cache..."
    
    local invalidation_id
    invalidation_id=$(aws cloudfront create-invalidation \
        --distribution-id "$ADMIN_DISTRIBUTION_ID" \
        --paths "/*" \
        --query 'Invalidation.Id' \
        --output text)
    
    log_success "CloudFront invalidation created: $invalidation_id"
    log_info "Changes will take 5-10 minutes to propagate globally"
}

# Test credentials
test_credentials() {
    log_info "Testing new credentials..."
    
    local auth_string
    auth_string=$(generate_auth_string "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
    
    log_info "New credentials:"
    log_info "  Username: $ADMIN_USERNAME"
    log_info "  Password: $ADMIN_PASSWORD"
    log_info "  Auth String: Basic $auth_string"
    
    log_warning "Please wait 5-10 minutes for CloudFront changes to propagate"
    log_info "Then try accessing the admin site with these credentials"
}

# Main function
main() {
    log_info "Resetting admin site credentials..."
    log_info "Username: $ADMIN_USERNAME"
    log_info "Password: $ADMIN_PASSWORD"
    log_info "Distribution ID: $ADMIN_DISTRIBUTION_ID"
    
    check_prerequisites
    update_cloudfront_function
    invalidate_cloudfront
    test_credentials
    
    log_success "Admin credentials reset completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Wait 5-10 minutes for CloudFront changes to propagate"
    log_info "2. Try accessing the admin site with the new credentials"
    log_info "3. If still having issues, try clearing browser cache/cookies"
    log_info ""
    log_info "Admin site URL: https://admin.robertconsulting.net"
    log_info "Username: $ADMIN_USERNAME"
    log_info "Password: $ADMIN_PASSWORD"
}

# Run main function
main "$@"
