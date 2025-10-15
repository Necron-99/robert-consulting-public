#!/bin/bash

# Import manually created AWS resources into Terraform state
# This script imports resources that exist in AWS but are not managed by Terraform

set -e

echo "📥 Importing manually created AWS resources into Terraform state..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}📊 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to import resource with error handling
import_resource() {
    local resource_type=$1
    local resource_name=$2
    local aws_id=$3
    
    echo "Importing $resource_type.$resource_name ($aws_id)..."
    if terraform import -lock=false "$resource_type.$resource_name" "$aws_id" 2>/dev/null; then
        print_success "Imported $resource_type.$resource_name"
    else
        print_warning "Failed to import $resource_type.$resource_name (may already be in state or not exist)"
    fi
}

print_header "Importing Lambda Functions"
# Import the dashboard stats refresher Lambda function
import_resource "aws_lambda_function" "stats_refresher" "dashboard-stats-refresher"

# Import the contact form API Lambda function
import_resource "aws_lambda_function" "contact_form" "contact-form-api"

print_header "Importing IAM Roles"
# Import Lambda execution roles
import_resource "aws_iam_role" "stats_refresher_role" "dashboard-stats-refresher-role"
import_resource "aws_iam_role" "contact_form_lambda_role" "contact-form-lambda-role"

print_header "Importing Secrets Manager Secrets"
# Import GitHub token secret
import_resource "aws_secretsmanager_secret" "github_token" "github-token-dashboard-stats"

print_header "Importing CloudWatch Log Groups"
# Import Lambda log groups
import_resource "aws_cloudwatch_log_group" "stats_refresher_logs" "/aws/lambda/dashboard-stats-refresher"
import_resource "aws_cloudwatch_log_group" "contact_form_logs" "/aws/lambda/contact-form-api"

print_header "Importing S3 Buckets"
# Import main website bucket
import_resource "aws_s3_bucket" "website_bucket" "robert-consulting-website"

# Import staging bucket
import_resource "aws_s3_bucket" "staging_bucket" "robert-consulting-staging-website"

# Import access logs bucket
import_resource "aws_s3_bucket" "access_logs_bucket" "robert-consulting-staging-access-logs"

print_header "Importing CloudFront Distributions"
# Import main website distribution
import_resource "aws_cloudfront_distribution" "website" "E36DBYPHUUKB3V"

# Import admin site distribution
import_resource "aws_cloudfront_distribution" "admin_site" "E1JE597A8ZZ547"

print_header "Importing Route 53 Resources"
# Import hosted zones (we'll need to get the actual zone IDs)
echo "Note: Route 53 zones need to be imported manually with their actual zone IDs"
echo "Run: terraform import aws_route53_zone.main Z27B3IO6HZ1QVN"
echo "Run: terraform import aws_route53_zone.admin Z2T2K691S6GS79"

print_header "Import Summary"
echo "✅ Import process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to see what changes are needed"
echo "2. Review the plan carefully before applying"
echo "3. Run 'terraform apply' to sync the state with actual resources"
echo "4. After successful apply, migrate to S3 backend"
echo ""
echo "💡 Tips:"
echo "- Use 'terraform state list' to see all managed resources"
echo "- Use 'terraform state show <resource>' to inspect specific resources"
echo "- Some resources may need manual configuration adjustments"
