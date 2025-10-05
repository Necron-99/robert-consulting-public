#!/bin/bash

# AWS Organizations Setup Script
# This script sets up the AWS Organizations structure for Robert Consulting

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

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "AWS CLI is installed"
}

# Check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    print_success "Terraform is installed"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS credentials configured for account: $ACCOUNT_ID"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform in org stack..."
    cd org
    terraform init
    print_success "Terraform initialized (org)"
}

# Plan Terraform changes
plan_terraform() {
    print_status "Planning Terraform changes (org)..."
    terraform plan -out=tfplan
    print_success "Terraform plan created (org)"
}

# Apply Terraform changes
apply_terraform() {
    print_status "Applying Terraform changes (org)..."
    terraform apply tfplan
    print_success "Terraform changes applied (org)"
    cd ..
}

# Create client account infrastructure
setup_client_account() {
    local client_name=$1
    local client_domain=$2
    
    print_status "Setting up infrastructure for $client_name ($client_domain)..."
    
    # Initialize Terraform in client directory (already contains its own stack)
    cd "clients/$client_name"
    terraform init
    terraform plan
    terraform apply -auto-approve
    
    cd ../..
    print_success "Client infrastructure setup completed for $client_name"
}

# Main setup function
main() {
    print_status "Starting AWS Organizations setup for Robert Consulting..."
    
    # Pre-flight checks
    check_aws_cli
    check_terraform
    check_aws_credentials
    
    # Initialize and apply organization structure
    init_terraform
    plan_terraform
    
    print_warning "This will create AWS Organizations and client accounts."
    print_warning "Make sure you have the necessary permissions and billing setup."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        
        # Setup client accounts
        setup_client_account "baileylessons" "baileylessons.com"
        
        print_success "AWS Organizations setup completed!"
        print_status "Next steps:"
        echo "1. Configure DNS for baileylessons.com with the provided name servers"
        echo "2. Set up cross-account access for management"
        echo "3. Configure billing and cost allocation tags"
        echo "4. Set up monitoring and alerting"
        
    else
        print_warning "Setup cancelled by user"
        exit 0
    fi
}

# Run main function
main "$@"
