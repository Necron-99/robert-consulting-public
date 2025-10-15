#!/bin/bash

# AWS Resource Audit Script
# This script identifies potentially unused AWS resources

set -e

echo "🔍 AWS Resource Audit - Identifying unused resources..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}📊 $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if resource is in Terraform state
is_managed_by_terraform() {
    local resource_type=$1
    local resource_id=$2
    
    if terraform state list | grep -q "${resource_type}\.${resource_id}"; then
        return 0
    else
        return 1
    fi
}

print_header "S3 Buckets"
echo "Checking S3 buckets..."
aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n' | while read bucket; do
    if [[ "$bucket" == *"robert-consulting"* ]] || [[ "$bucket" == *"terraform"* ]]; then
        if is_managed_by_terraform "aws_s3_bucket" "$bucket"; then
            print_success "S3 bucket '$bucket' is managed by Terraform"
        else
            print_warning "S3 bucket '$bucket' is NOT managed by Terraform"
        fi
    fi
done

print_header "Lambda Functions"
echo "Checking Lambda functions..."
aws lambda list-functions --query 'Functions[].FunctionName' --output text | tr '\t' '\n' | while read func; do
    if is_managed_by_terraform "aws_lambda_function" "$func"; then
        print_success "Lambda function '$func' is managed by Terraform"
    else
        print_warning "Lambda function '$func' is NOT managed by Terraform"
    fi
done

print_header "CloudFront Distributions"
echo "Checking CloudFront distributions..."
aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text | tr '\t' '\n' | while read dist; do
    if is_managed_by_terraform "aws_cloudfront_distribution" "$dist"; then
        print_success "CloudFront distribution '$dist' is managed by Terraform"
    else
        print_warning "CloudFront distribution '$dist' is NOT managed by Terraform"
    fi
done

print_header "Route 53 Hosted Zones"
echo "Checking Route 53 hosted zones..."
aws route53 list-hosted-zones --query 'HostedZones[].Id' --output text | tr '\t' '\n' | while read zone; do
    zone_id=$(echo $zone | sed 's|/hostedzone/||')
    if is_managed_by_terraform "aws_route53_zone" "$zone_id"; then
        print_success "Route 53 zone '$zone_id' is managed by Terraform"
    else
        print_warning "Route 53 zone '$zone_id' is NOT managed by Terraform"
    fi
done

print_header "IAM Roles"
echo "Checking IAM roles..."
aws iam list-roles --query 'Roles[?contains(RoleName, `robert`) || contains(RoleName, `terraform`) || contains(RoleName, `lambda`)].RoleName' --output text | tr '\t' '\n' | while read role; do
    if is_managed_by_terraform "aws_iam_role" "$role"; then
        print_success "IAM role '$role' is managed by Terraform"
    else
        print_warning "IAM role '$role' is NOT managed by Terraform"
    fi
done

print_header "Secrets Manager Secrets"
echo "Checking Secrets Manager secrets..."
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `github`) || contains(Name, `robert`)].Name' --output text | tr '\t' '\n' | while read secret; do
    if is_managed_by_terraform "aws_secretsmanager_secret" "$secret"; then
        print_success "Secret '$secret' is managed by Terraform"
    else
        print_warning "Secret '$secret' is NOT managed by Terraform"
    fi
done

print_header "CloudWatch Log Groups"
echo "Checking CloudWatch log groups..."
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `/aws/lambda/`) || contains(logGroupName, `robert`)].logGroupName' --output text | tr '\t' '\n' | while read loggroup; do
    if is_managed_by_terraform "aws_cloudwatch_log_group" "$loggroup"; then
        print_success "Log group '$loggroup' is managed by Terraform"
    else
        print_warning "Log group '$loggroup' is NOT managed by Terraform"
    fi
done

echo ""
print_header "Summary"
echo "This audit shows which resources are managed by Terraform vs manually created."
echo "Resources marked as 'NOT managed by Terraform' should be either:"
echo "1. Imported into Terraform state, or"
echo "2. Removed if they're no longer needed"
echo ""
echo "To import a resource: terraform import <resource_type>.<resource_name> <aws_resource_id>"
echo "To remove a resource: terraform destroy -target=<resource_type>.<resource_name>"
