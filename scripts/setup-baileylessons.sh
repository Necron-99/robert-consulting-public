#!/bin/bash

# Bailey Lessons Setup Script
# Quick setup for baileylessons.com deployment

set -e

# Configuration
CLIENT_NAME="baileylessons"
CLIENT_REPO="rsbailey/baileylessons.com"  # Update with actual repository
DOMAIN="baileylessons.com"
BUCKET_NAME="baileylessons-website-$(date +%Y%m%d)-$(openssl rand -hex 4)"

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
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Setup Bailey Lessons
setup_baileylessons() {
    log_info "Setting up Bailey Lessons deployment..."
    
    # Run the general setup script
    ./scripts/setup-client-deployment.sh "$CLIENT_NAME" "$CLIENT_REPO" "$DOMAIN"
    
    log_success "Bailey Lessons setup completed!"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying Bailey Lessons infrastructure..."
    
    cd "clients/$CLIENT_NAME"
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan
    
    # Apply infrastructure
    terraform apply -auto-approve
    
    # Get outputs
    local cloudfront_id
    cloudfront_id=$(terraform output -raw cloudfront_distribution_id)
    
    # Update configuration
    jq --arg cf_id "$cloudfront_id" '.cloudfront_distribution_id = $cf_id | .status = "active"' config.json > config.json.tmp && mv config.json.tmp config.json
    
    log_success "Infrastructure deployed successfully!"
    log_info "CloudFront Distribution ID: $cloudfront_id"
    
    cd ../..
}

# Deploy content
deploy_content() {
    log_info "Deploying Bailey Lessons content..."
    
    cd "clients/$CLIENT_NAME"
    ./deploy.sh
    cd ../..
    
    log_success "Content deployed successfully!"
}

# Main function
main() {
    log_info "Setting up Bailey Lessons deployment system..."
    log_info "Client: $CLIENT_NAME"
    log_info "Repository: $CLIENT_REPO"
    log_info "Domain: $DOMAIN"
    log_info "S3 Bucket: $BUCKET_NAME"
    
    check_prerequisites
    setup_baileylessons
    deploy_infrastructure
    deploy_content
    
    log_success "Bailey Lessons deployment system setup completed!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Access admin interface: /admin/client-deployment.html"
    log_info "2. Verify deployment at: https://$DOMAIN"
    log_info "3. Monitor deployments via GitHub Actions"
    log_info ""
    log_info "Manual deployment:"
    log_info "  cd clients/$CLIENT_NAME && ./deploy.sh"
    log_info ""
    log_info "Admin interface:"
    log_info "  /admin/client-deployment.html"
}

# Run main function
main "$@"
