#!/bin/bash

# 🔒 Security Vulnerability Verification Script
# This script verifies actual infrastructure state vs. code vulnerabilities

set -e

echo "🔍 === SECURITY VULNERABILITY VERIFICATION ==="
echo "📝 Verifying actual infrastructure state against reported vulnerabilities"
echo "✅ This ensures we only fix real issues, not false positives"
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

# Function to verify S3 bucket security
verify_s3_security() {
    echo -e "${BLUE}🔍 Checking S3 bucket security...${NC}"
    
    # Get all S3 buckets
    buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)
    
    for bucket in $buckets; do
        echo -e "${YELLOW}📦 Checking bucket: $bucket${NC}"
        
        # Check encryption
        echo "  🔐 Checking encryption..."
        if aws s3api get-bucket-encryption --bucket "$bucket" &> /dev/null; then
            encryption=$(aws s3api get-bucket-encryption --bucket "$bucket" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text)
            echo -e "    ${GREEN}✅ Encryption: $encryption${NC}"
        else
            echo -e "    ${RED}❌ No encryption configured${NC}"
        fi
        
        # Check public access block
        echo "  🚫 Checking public access block..."
        if aws s3api get-public-access-block --bucket "$bucket" &> /dev/null; then
            pab=$(aws s3api get-public-access-block --bucket "$bucket")
            block_public_acls=$(echo "$pab" | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls')
            block_public_policy=$(echo "$pab" | jq -r '.PublicAccessBlockConfiguration.BlockPublicPolicy')
            ignore_public_acls=$(echo "$pab" | jq -r '.PublicAccessBlockConfiguration.IgnorePublicAcls')
            restrict_public_buckets=$(echo "$pab" | jq -r '.PublicAccessBlockConfiguration.RestrictPublicBuckets')
            
            if [[ "$block_public_acls" == "true" && "$block_public_policy" == "true" && "$ignore_public_acls" == "true" && "$restrict_public_buckets" == "true" ]]; then
                echo -e "    ${GREEN}✅ Public access properly blocked${NC}"
            else
                echo -e "    ${RED}❌ Public access not fully blocked${NC}"
                echo "      BlockPublicAcls: $block_public_acls"
                echo "      BlockPublicPolicy: $block_public_policy"
                echo "      IgnorePublicAcls: $ignore_public_acls"
                echo "      RestrictPublicBuckets: $restrict_public_buckets"
            fi
        else
            echo -e "    ${RED}❌ No public access block configured${NC}"
        fi
        
        # Check bucket policy
        echo "  📋 Checking bucket policy..."
        if aws s3api get-bucket-policy --bucket "$bucket" &> /dev/null; then
            policy=$(aws s3api get-bucket-policy --bucket "$bucket" --query 'Policy' --output text | jq .)
            echo -e "    ${YELLOW}⚠️  Bucket has policy (review manually)${NC}"
        else
            echo -e "    ${GREEN}✅ No bucket policy (good for security)${NC}"
        fi
        
        echo ""
    done
}

# Function to verify SNS security
verify_sns_security() {
    echo -e "${BLUE}🔍 Checking SNS topic security...${NC}"
    
    # Get all SNS topics
    topics=$(aws sns list-topics --query 'Topics[].TopicArn' --output text)
    
    if [[ -z "$topics" ]]; then
        echo -e "${GREEN}✅ No SNS topics found${NC}"
        return
    fi
    
    for topic_arn in $topics; do
        echo -e "${YELLOW}📢 Checking topic: $topic_arn${NC}"
        
        # Check topic attributes with error handling
        if attributes=$(aws sns get-topic-attributes --topic-arn "$topic_arn" 2>/dev/null); then
            # Check for KMS encryption
            kms_key_id=$(echo "$attributes" | jq -r '.Attributes.KmsMasterKeyId')
            if [[ "$kms_key_id" != "null" && "$kms_key_id" != "" ]]; then
                echo -e "    ${GREEN}✅ KMS encryption enabled: $kms_key_id${NC}"
            else
                echo -e "    ${RED}❌ No KMS encryption configured${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠️  Could not access topic (may be deleted or inaccessible)${NC}"
        fi
        
        echo ""
    done
}

# Function to verify CloudFront security
verify_cloudfront_security() {
    echo -e "${BLUE}🔍 Checking CloudFront security...${NC}"
    
    # Get all CloudFront distributions
    distributions=$(aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text)
    
    if [[ -z "$distributions" ]]; then
        echo -e "${GREEN}✅ No CloudFront distributions found${NC}"
        return
    fi
    
    for dist_id in $distributions; do
        echo -e "${YELLOW}🌐 Checking distribution: $dist_id${NC}"
        
        # Get distribution details with error handling
        if dist_details=$(aws cloudfront get-distribution --id "$dist_id" 2>/dev/null); then
            # Check for WAF association
            web_acl_id=$(echo "$dist_details" | jq -r '.Distribution.DistributionConfig.WebACLId')
            if [[ "$web_acl_id" != "null" && "$web_acl_id" != "" ]]; then
                echo -e "    ${GREEN}✅ WAF associated: $web_acl_id${NC}"
            else
                echo -e "    ${RED}❌ No WAF associated${NC}"
            fi
            
            # Check for security headers
            security_headers=$(echo "$dist_details" | jq -r '.Distribution.DistributionConfig.DefaultCacheBehavior.ResponseHeadersPolicyId')
            if [[ "$security_headers" != "null" && "$security_headers" != "" ]]; then
                echo -e "    ${GREEN}✅ Security headers policy: $security_headers${NC}"
            else
                echo -e "    ${YELLOW}⚠️  No security headers policy${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠️  Could not access distribution (may be deleted or inaccessible)${NC}"
        fi
        
        echo ""
    done
}

# Function to generate security report
generate_security_report() {
    echo -e "${BLUE}📊 Generating security report...${NC}"
    
    report_file="security-assessment-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🔒 Security Assessment Report
Generated: $(date)

## 📋 Executive Summary
This report documents the current security posture of AWS infrastructure.

## 🔍 Findings

### S3 Bucket Security
$(aws s3api list-buckets --query 'Buckets[].Name' --output text | while read bucket; do
    echo "#### Bucket: $bucket"
    if aws s3api get-bucket-encryption --bucket "$bucket" &> /dev/null; then
        echo "- ✅ Encryption: Configured"
    else
        echo "- ❌ Encryption: Not configured"
    fi
    
    if aws s3api get-public-access-block --bucket "$bucket" &> /dev/null; then
        echo "- ✅ Public Access Block: Configured"
    else
        echo "- ❌ Public Access Block: Not configured"
    fi
    echo ""
done)

### SNS Topic Security
$(aws sns list-topics --query 'Topics[].TopicArn' --output text | while read topic; do
    echo "#### Topic: $topic"
    if kms_key=$(aws sns get-topic-attributes --topic-arn "$topic" --query 'Attributes.KmsMasterKeyId' --output text 2>/dev/null); then
        if [[ "$kms_key" != "null" && "$kms_key" != "" ]]; then
            echo "- ✅ KMS Encryption: $kms_key"
        else
            echo "- ❌ KMS Encryption: Not configured"
        fi
    else
        echo "- ⚠️ KMS Encryption: Could not access topic"
    fi
    echo ""
done)

### CloudFront Security
$(aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text | while read dist_id; do
    echo "#### Distribution: $dist_id"
    if waf_id=$(aws cloudfront get-distribution --id "$dist_id" --query 'Distribution.DistributionConfig.WebACLId' --output text 2>/dev/null); then
        if [[ "$waf_id" != "null" && "$waf_id" != "" ]]; then
            echo "- ✅ WAF: $waf_id"
        else
            echo "- ❌ WAF: Not configured"
        fi
    else
        echo "- ⚠️ WAF: Could not access distribution"
    fi
    echo ""
done)

## 🎯 Recommendations
1. Enable S3 bucket encryption with KMS
2. Configure S3 public access blocks
3. Enable SNS topic encryption
4. Associate WAF with CloudFront distributions

## 📞 Next Steps
1. Review findings with security team
2. Prioritize remediation based on risk
3. Implement fixes in staging environment
4. Deploy to production after validation
EOF

    echo -e "${GREEN}✅ Security report generated: $report_file${NC}"
}

# Main execution
main() {
    echo "🚀 Starting security vulnerability verification..."
    echo ""
    
    # Check prerequisites
    check_aws_cli
    
    # Verify each service
    verify_s3_security
    verify_sns_security
    verify_cloudfront_security
    
    # Generate report
    generate_security_report
    
    echo -e "${GREEN}🎯 Security verification complete!${NC}"
    echo -e "${BLUE}📊 Review the generated report for detailed findings.${NC}"
}

# Run main function
main "$@"
