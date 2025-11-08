#!/bin/bash

# Import Existing Resources from Terraform Plan
# This script helps import resources that already exist in AWS but aren't in Terraform state

set -e

echo "🔍 === IDENTIFYING EXISTING RESOURCES TO IMPORT ==="
echo ""

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

# Function to check if resource exists and import it
check_and_import() {
    local resource_type=$1
    local resource_name=$2
    local aws_id=$3
    local check_command=$4
    
    echo "Checking $resource_type.$resource_name..."
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo "  Resource exists in AWS: $aws_id"
        echo "  Importing..."
        if terraform import -lock=false "$resource_type.$resource_name" "$aws_id" 2>/dev/null; then
            print_success "Imported $resource_type.$resource_name"
            return 0
        else
            print_warning "Failed to import (may already be in state)"
            return 1
        fi
    else
        print_warning "Resource does not exist in AWS, will be created"
        return 1
    fi
}

ZONE_ID="Z05682173V2H2T5QWU8P0"
BAILEYLESSONS_ZONE_ID="Z01009052GCOJI1M2TTF7"

print_header "Checking Route53 Records"

# Check root domain A record
ROOT_A=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Name=='robertconsulting.net.' && Type=='A'].Name" --output text 2>/dev/null)
if [ ! -z "$ROOT_A" ]; then
    echo "Found root domain A record, importing..."
    terraform import -lock=false aws_route53_record.root_domain "${ZONE_ID}_robertconsulting.net_A" 2>/dev/null && print_success "Imported root domain A record" || print_warning "Already in state or import failed"
else
    print_warning "Root domain A record not found in Route53"
fi

# Check root domain AAAA record
ROOT_AAAA=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Name=='robertconsulting.net.' && Type=='AAAA'].Name" --output text 2>/dev/null)
if [ ! -z "$ROOT_AAAA" ]; then
    echo "Found root domain AAAA record, importing..."
    terraform import -lock=false aws_route53_record.root_domain_ipv6 "${ZONE_ID}_robertconsulting.net_AAAA" 2>/dev/null && print_success "Imported root domain AAAA record" || print_warning "Already in state or import failed"
else
    print_warning "Root domain AAAA record not found in Route53"
fi

# Check staging domain A record
STAGING_A=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Name=='staging.robertconsulting.net.' && Type=='A'].Name" --output text 2>/dev/null)
if [ ! -z "$STAGING_A" ]; then
    echo "Found staging domain A record, importing..."
    terraform import -lock=false aws_route53_record.staging_domain "${ZONE_ID}_staging.robertconsulting.net_A" 2>/dev/null && print_success "Imported staging domain A record" || print_warning "Already in state or import failed"
else
    print_warning "Staging domain A record not found in Route53"
fi

print_header "Checking Bailey Lessons Resources"

# Check Bailey Lessons CloudFront distribution
BAILEYLESSONS_CF=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items,'admin.baileylessons.com')].Id" --output text 2>/dev/null)
if [ ! -z "$BAILEYLESSONS_CF" ]; then
    echo "Found Bailey Lessons CloudFront distribution: $BAILEYLESSONS_CF"
    echo "Importing..."
    terraform import -lock=false module.baileylessons.aws_cloudfront_distribution.admin "$BAILEYLESSONS_CF" 2>/dev/null && print_success "Imported Bailey Lessons CloudFront" || print_warning "Already in state or import failed"
else
    print_warning "Bailey Lessons CloudFront distribution not found"
fi

# Check Bailey Lessons Route53 record
BAILEYLESSONS_R53=$(aws route53 list-resource-record-sets --hosted-zone-id $BAILEYLESSONS_ZONE_ID --query "ResourceRecordSets[?Name=='admin.baileylessons.com.' && Type=='A'].Name" --output text 2>/dev/null)
if [ ! -z "$BAILEYLESSONS_R53" ]; then
    echo "Found Bailey Lessons Route53 record, importing..."
    terraform import -lock=false module.baileylessons.aws_route53_record.admin "${BAILEYLESSONS_ZONE_ID}_admin.baileylessons.com_A" 2>/dev/null && print_success "Imported Bailey Lessons Route53 record" || print_warning "Already in state or import failed"
else
    print_warning "Bailey Lessons Route53 record not found"
fi

# Check Bailey Lessons S3 bucket policy
BAILEYLESSONS_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name,'baileylessons-admin')].Name" --output text 2>/dev/null)
if [ ! -z "$BAILEYLESSONS_BUCKET" ]; then
    echo "Found Bailey Lessons S3 bucket: $BAILEYLESSONS_BUCKET"
    echo "Importing bucket policy..."
    terraform import -lock=false module.baileylessons.aws_s3_bucket_policy.admin "$BAILEYLESSONS_BUCKET" 2>/dev/null && print_success "Imported Bailey Lessons S3 bucket policy" || print_warning "Already in state or import failed"
else
    print_warning "Bailey Lessons S3 bucket not found"
fi

print_header "Checking API Gateway Resources"

# Check API Gateway usage plan
USAGE_PLAN=$(aws apigateway get-usage-plans --query "items[?name=='contact-form-usage-plan'].id" --output text 2>/dev/null)
if [ ! -z "$USAGE_PLAN" ]; then
    echo "Found API Gateway usage plan: $USAGE_PLAN"
    echo "Importing..."
    terraform import -lock=false aws_api_gateway_usage_plan.contact_form_usage_plan "$USAGE_PLAN" 2>/dev/null && print_success "Imported usage plan" || print_warning "Already in state or import failed"
else
    print_warning "API Gateway usage plan not found"
fi

# Check API Gateway usage plan key
API_KEY_ID="9udpgoq4u1"
if [ ! -z "$USAGE_PLAN" ]; then
    echo "Importing usage plan key..."
    terraform import -lock=false aws_api_gateway_usage_plan_key.contact_form_usage_plan_key "${USAGE_PLAN}/${API_KEY_ID}" 2>/dev/null && print_success "Imported usage plan key" || print_warning "Already in state or import failed"
fi

# Check Lambda permission for contact form
LAMBDA_PERM=$(aws lambda get-policy --function-name contact-form-api --query 'Policy' --output text 2>/dev/null | grep -q "AllowExecutionFromAPIGateway" && echo "exists" || echo "")
if [ ! -z "$LAMBDA_PERM" ]; then
    echo "Found Lambda permission for contact form API Gateway"
    echo "Note: Lambda permissions are tricky to import - may need manual import"
    print_warning "Lambda permission may need manual import"
fi

print_header "Checking WAF Associations"

# Check WAF association for contact form API Gateway
API_GATEWAY_ID="4a01s5j8f5"
WAF_ASSOC=$(aws wafv2 list-resources-for-web-acl --web-acl-arn "arn:aws:wafv2:us-east-1:228480945348:regional/webacl/contact-form-waf/80b89e94-d5b4-4f92-a31d-1f5c0290c1db" --resource-type APIGATEWAY --query "ResourceArns[?contains(@,'$API_GATEWAY_ID')]" --output text 2>/dev/null)
if [ ! -z "$WAF_ASSOC" ]; then
    echo "Found WAF association for contact form API Gateway"
    echo "Importing..."
    terraform import -lock=false aws_wafv2_web_acl_association.contact_form_waf_association "arn:aws:apigateway:us-east-1::/restapis/${API_GATEWAY_ID}/stages/prod" 2>/dev/null && print_success "Imported WAF association" || print_warning "Already in state or import failed"
else
    print_warning "WAF association not found"
fi

print_header "Checking CloudWatch Alarms"

# Check staging high error rate alarm
STAGING_ALARM=$(aws cloudwatch describe-alarms --alarm-names "staging-high-error-rate" --query "MetricAlarms[0].AlarmName" --output text 2>/dev/null)
if [ ! -z "$STAGING_ALARM" ] && [ "$STAGING_ALARM" != "None" ]; then
    echo "Found staging high error rate alarm, importing..."
    terraform import -lock=false aws_cloudwatch_metric_alarm.staging_high_error_rate "staging-high-error-rate" 2>/dev/null && print_success "Imported staging alarm" || print_warning "Already in state or import failed"
else
    print_warning "Staging alarm not found"
fi

print_header "Checking Lambda Functions"

# Check Plex analyzer Lambda in module
PLEX_LAMBDA=$(aws lambda get-function --function-name plex-recommendations-analyzer --query 'Configuration.FunctionName' --output text 2>/dev/null)
if [ ! -z "$PLEX_LAMBDA" ] && [ "$PLEX_LAMBDA" != "None" ]; then
    echo "Found Plex analyzer Lambda: $PLEX_LAMBDA"
    echo "Importing..."
    terraform import -lock=false module.plex_recommendations.aws_lambda_function.plex_analyzer "$PLEX_LAMBDA" 2>/dev/null && print_success "Imported Plex analyzer Lambda" || print_warning "Already in state or import failed"
else
    print_warning "Plex analyzer Lambda not found"
fi

# Check Plex Lambda S3 policy
PLEX_ROLE="plex-lambda-role"
POLICY_EXISTS=$(aws iam list-role-policies --role-name "$PLEX_ROLE" --query "PolicyNames[?@=='plex-s3-access']" --output text 2>/dev/null)
if [ ! -z "$POLICY_EXISTS" ] && [ "$POLICY_EXISTS" != "None" ]; then
    echo "Found Plex Lambda S3 policy, importing..."
    terraform import -lock=false aws_iam_role_policy.plex_lambda_s3_policy "${PLEX_ROLE}:plex-s3-access" 2>/dev/null && print_success "Imported Plex Lambda S3 policy" || print_warning "Already in state or import failed"
else
    print_warning "Plex Lambda S3 policy not found"
fi

echo ""
print_header "Import Summary"
echo "✅ Import process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to see remaining changes"
echo "2. Review the plan carefully"
echo "3. Apply remaining changes if needed"
echo ""
echo "💡 Note: Some resources may need manual import if the automatic import failed"
echo "   Check the warnings above for resources that couldn't be imported"

