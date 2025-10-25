#!/bin/bash

# 🔍 Terraform Infrastructure Drift Analysis Script
# This script compares Terraform state with actual AWS resources

set -e

echo "🔍 === TERRAFORM DRIFT ANALYSIS ==="
echo "📝 Comparing Terraform state with actual AWS resources"
echo "✅ This ensures infrastructure consistency before security fixes"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI first.${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ AWS CLI configured and ready${NC}"
}

# Function to check if Terraform is available
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform not found. Please install Terraform first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Terraform available${NC}"
}

# Function to check S3 bucket drift
check_s3_drift() {
    echo -e "${BLUE}📦 Checking S3 bucket drift...${NC}"
    
    # Get Terraform-managed buckets
    terraform_buckets=$(terraform state list | grep aws_s3_bucket | sed 's/aws_s3_bucket\.//' || echo "")
    
    # Get actual AWS buckets
    aws_buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)
    
    echo -e "${YELLOW}Terraform-managed buckets:${NC}"
    if [[ -n "$terraform_buckets" ]]; then
        echo "$terraform_buckets" | while read bucket; do
            echo "  - $bucket"
        done
    else
        echo "  (none found)"
    fi
    
    echo -e "${YELLOW}AWS buckets:${NC}"
    echo "$aws_buckets" | while read bucket; do
        echo "  - $bucket"
    done
    
    echo ""
    echo -e "${BLUE}📊 S3 Drift Analysis:${NC}"
    
    # Find orphaned buckets (in AWS but not in Terraform)
    orphaned_count=0
    for bucket in $aws_buckets; do
        if [[ -n "$terraform_buckets" ]] && echo "$terraform_buckets" | grep -q "^$bucket$"; then
            echo -e "  ${GREEN}✅ $bucket - Managed by Terraform${NC}"
        else
            echo -e "  ${RED}❌ $bucket - Orphaned (not in Terraform)${NC}"
            orphaned_count=$((orphaned_count + 1))
        fi
    done
    
    # Find missing buckets (in Terraform but not in AWS)
    missing_count=0
    if [[ -n "$terraform_buckets" ]]; then
        for bucket in $terraform_buckets; do
            if echo "$aws_buckets" | grep -q "^$bucket$"; then
                echo -e "  ${GREEN}✅ $bucket - Exists in AWS${NC}"
            else
                echo -e "  ${YELLOW}⚠️  $bucket - Missing in AWS (may need deployment)${NC}"
                missing_count=$((missing_count + 1))
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}📈 S3 Summary:${NC}"
    echo "  - Orphaned buckets: $orphaned_count"
    echo "  - Missing buckets: $missing_count"
    echo ""
}

# Function to check SNS topic drift
check_sns_drift() {
    echo -e "${BLUE}📢 Checking SNS topic drift...${NC}"
    
    # Get Terraform-managed topics
    terraform_topics=$(terraform state list | grep aws_sns_topic | sed 's/aws_sns_topic\.//' || echo "")
    
    # Get actual AWS topics
    aws_topics=$(aws sns list-topics --query 'Topics[].TopicArn' --output text | sed 's/.*://' || echo "")
    
    echo -e "${YELLOW}Terraform-managed topics:${NC}"
    if [[ -n "$terraform_topics" ]]; then
        echo "$terraform_topics" | while read topic; do
            echo "  - $topic"
        done
    else
        echo "  (none found)"
    fi
    
    echo -e "${YELLOW}AWS topics:${NC}"
    if [[ -n "$aws_topics" ]]; then
        echo "$aws_topics" | while read topic; do
            echo "  - $topic"
        done
    else
        echo "  (none found)"
    fi
    
    echo ""
    echo -e "${BLUE}📊 SNS Drift Analysis:${NC}"
    
    # Find orphaned topics
    orphaned_count=0
    if [[ -n "$aws_topics" ]]; then
        for topic in $aws_topics; do
            if [[ -n "$terraform_topics" ]] && echo "$terraform_topics" | grep -q "^$topic$"; then
                echo -e "  ${GREEN}✅ $topic - Managed by Terraform${NC}"
            else
                echo -e "  ${RED}❌ $topic - Orphaned (not in Terraform)${NC}"
                orphaned_count=$((orphaned_count + 1))
            fi
        done
    fi
    
    # Find missing topics
    missing_count=0
    if [[ -n "$terraform_topics" ]]; then
        for topic in $terraform_topics; do
            if [[ -n "$aws_topics" ]] && echo "$aws_topics" | grep -q "^$topic$"; then
                echo -e "  ${GREEN}✅ $topic - Exists in AWS${NC}"
            else
                echo -e "  ${YELLOW}⚠️  $topic - Missing in AWS (may need deployment)${NC}"
                missing_count=$((missing_count + 1))
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}📈 SNS Summary:${NC}"
    echo "  - Orphaned topics: $orphaned_count"
    echo "  - Missing topics: $missing_count"
    echo ""
}

# Function to check CloudFront distribution drift
check_cloudfront_drift() {
    echo -e "${BLUE}🌐 Checking CloudFront distribution drift...${NC}"
    
    # Get Terraform-managed distributions
    terraform_distributions=$(terraform state list | grep aws_cloudfront_distribution | sed 's/aws_cloudfront_distribution\.//' || echo "")
    
    # Get actual AWS distributions
    aws_distributions=$(aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text || echo "")
    
    echo -e "${YELLOW}Terraform-managed distributions:${NC}"
    if [[ -n "$terraform_distributions" ]]; then
        echo "$terraform_distributions" | while read dist; do
            echo "  - $dist"
        done
    else
        echo "  (none found)"
    fi
    
    echo -e "${YELLOW}AWS distributions:${NC}"
    if [[ -n "$aws_distributions" ]]; then
        echo "$aws_distributions" | while read dist; do
            echo "  - $dist"
        done
    else
        echo "  (none found)"
    fi
    
    echo ""
    echo -e "${BLUE}📊 CloudFront Drift Analysis:${NC}"
    
    # Find orphaned distributions
    orphaned_count=0
    if [[ -n "$aws_distributions" ]]; then
        for dist in $aws_distributions; do
            if [[ -n "$terraform_distributions" ]] && echo "$terraform_distributions" | grep -q "^$dist$"; then
                echo -e "  ${GREEN}✅ $dist - Managed by Terraform${NC}"
            else
                echo -e "  ${RED}❌ $dist - Orphaned (not in Terraform)${NC}"
                orphaned_count=$((orphaned_count + 1))
            fi
        done
    fi
    
    # Find missing distributions
    missing_count=0
    if [[ -n "$terraform_distributions" ]]; then
        for dist in $terraform_distributions; do
            if [[ -n "$aws_distributions" ]] && echo "$aws_distributions" | grep -q "^$dist$"; then
                echo -e "  ${GREEN}✅ $dist - Exists in AWS${NC}"
            else
                echo -e "  ${YELLOW}⚠️  $dist - Missing in AWS (may need deployment)${NC}"
                missing_count=$((missing_count + 1))
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}📈 CloudFront Summary:${NC}"
    echo "  - Orphaned distributions: $orphaned_count"
    echo "  - Missing distributions: $missing_count"
    echo ""
}

# Function to check Lambda function drift
check_lambda_drift() {
    echo -e "${BLUE}⚡ Checking Lambda function drift...${NC}"
    
    # Get Terraform-managed Lambda functions
    terraform_functions=$(terraform state list | grep aws_lambda_function | sed 's/aws_lambda_function\.//' || echo "")
    
    # Get actual AWS Lambda functions
    aws_functions=$(aws lambda list-functions --query 'Functions[].FunctionName' --output text || echo "")
    
    echo -e "${YELLOW}Terraform-managed Lambda functions:${NC}"
    if [[ -n "$terraform_functions" ]]; then
        echo "$terraform_functions" | while read func; do
            echo "  - $func"
        done
    else
        echo "  (none found)"
    fi
    
    echo -e "${YELLOW}AWS Lambda functions:${NC}"
    if [[ -n "$aws_functions" ]]; then
        echo "$aws_functions" | while read func; do
            echo "  - $func"
        done
    else
        echo "  (none found)"
    fi
    
    echo ""
    echo -e "${BLUE}📊 Lambda Drift Analysis:${NC}"
    
    # Find orphaned functions
    orphaned_count=0
    if [[ -n "$aws_functions" ]]; then
        for func in $aws_functions; do
            if [[ -n "$terraform_functions" ]] && echo "$terraform_functions" | grep -q "^$func$"; then
                echo -e "  ${GREEN}✅ $func - Managed by Terraform${NC}"
            else
                echo -e "  ${RED}❌ $func - Orphaned (not in Terraform)${NC}"
                orphaned_count=$((orphaned_count + 1))
            fi
        done
    fi
    
    # Find missing functions
    missing_count=0
    if [[ -n "$terraform_functions" ]]; then
        for func in $terraform_functions; do
            if [[ -n "$aws_functions" ]] && echo "$aws_functions" | grep -q "^$func$"; then
                echo -e "  ${GREEN}✅ $func - Exists in AWS${NC}"
            else
                echo -e "  ${YELLOW}⚠️  $func - Missing in AWS (may need deployment)${NC}"
                missing_count=$((missing_count + 1))
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}📈 Lambda Summary:${NC}"
    echo "  - Orphaned functions: $orphaned_count"
    echo "  - Missing functions: $missing_count"
    echo ""
}

# Function to generate drift report
generate_drift_report() {
    echo -e "${BLUE}📊 Generating drift analysis report...${NC}"
    
    report_file="terraform-drift-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔍 Terraform Infrastructure Drift Analysis Report
Generated: $(date)

## 📋 Executive Summary
This report documents the drift between Terraform state and actual AWS infrastructure.

## 🔍 Findings

### S3 Bucket Drift
$(terraform state list | grep aws_s3_bucket | sed 's/aws_s3_bucket\.//' | while read bucket; do
    if aws s3api head-bucket --bucket "$bucket" &> /dev/null; then
        echo "- ✅ $bucket: Managed and exists"
    else
        echo "- ❌ $bucket: Managed but missing in AWS"
    fi
done)

### SNS Topic Drift
$(terraform state list | grep aws_sns_topic | sed 's/aws_sns_topic\.//' | while read topic; do
    if aws sns get-topic-attributes --topic-arn "arn:aws:sns:us-east-1:$(aws sts get-caller-identity --query Account --output text):$topic" &> /dev/null; then
        echo "- ✅ $topic: Managed and exists"
    else
        echo "- ❌ $topic: Managed but missing in AWS"
    fi
done)

### CloudFront Distribution Drift
$(terraform state list | grep aws_cloudfront_distribution | sed 's/aws_cloudfront_distribution\.//' | while read dist; do
    if aws cloudfront get-distribution --id "$dist" &> /dev/null; then
        echo "- ✅ $dist: Managed and exists"
    else
        echo "- ❌ $dist: Managed but missing in AWS"
    fi
done)

## 🎯 Recommendations
1. Import orphaned resources into Terraform
2. Deploy missing resources
3. Clean up unnecessary resources
4. Implement security hardening

## 📞 Next Steps
1. Review findings with team
2. Prioritize cleanup based on business impact
3. Implement fixes in staging environment
4. Deploy to production after validation
EOF

    echo -e "${GREEN}✅ Drift analysis report generated: $report_file${NC}"
}

# Main execution
main() {
    echo "🚀 Starting Terraform drift analysis..."
    echo ""
    
    # Check prerequisites
    check_aws_cli
    check_terraform
    
    # Check each service
    check_s3_drift
    check_sns_drift
    check_cloudfront_drift
    check_lambda_drift
    
    # Generate report
    generate_drift_report
    
    echo -e "${GREEN}🎯 Terraform drift analysis complete!${NC}"
    echo -e "${BLUE}📊 Review the generated report for detailed findings.${NC}"
}

# Run main function
main "$@"
