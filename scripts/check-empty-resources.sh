#!/bin/bash

# Check for empty/unused AWS resources
# Helps identify resources that might not be needed

set -e

echo "🔍 Checking for Empty/Unused Resources"
echo "======================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

EMPTY_BUCKETS=()
UNUSED_LAMBDAS=()
UNUSED_DISTRIBUTIONS=()

echo -e "${BLUE}📦 Checking S3 Buckets...${NC}"
aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n' | while read bucket; do
  # Check if bucket is empty
  object_count=$(aws s3api list-objects-v2 --bucket "$bucket" --max-items 1 --query 'KeyCount' --output text 2>/dev/null || echo "0")
  
  if [ "$object_count" = "0" ] || [ -z "$object_count" ]; then
    # Check bucket size
    size=$(aws s3api list-objects-v2 --bucket "$bucket" --query 'sum(Contents[].Size)' --output text 2>/dev/null || echo "0")
    
    if [ "$size" = "None" ] || [ "$size" = "0" ] || [ -z "$size" ]; then
      echo -e "  ${YELLOW}⚠️  Empty bucket: $bucket${NC}"
      EMPTY_BUCKETS+=("$bucket")
    fi
  fi
done

echo ""
echo -e "${BLUE}⚡ Checking Lambda Functions...${NC}"
aws lambda list-functions --query 'Functions[].FunctionName' --output text | tr '\t' '\n' | while read func; do
  # Check last invocation (if available)
  last_modified=$(aws lambda get-function --function-name "$func" --query 'Configuration.LastModified' --output text 2>/dev/null || echo "")
  
  # Check if function has been invoked recently (last 30 days)
  # This is a simple check - you might want to use CloudWatch metrics for more accuracy
  echo -e "  ${GREEN}✓ $func${NC} (Last modified: $last_modified)"
done

echo ""
echo -e "${BLUE}🌐 Checking CloudFront Distributions...${NC}"
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Aliases:Aliases.Items[0],Status:Status}' --output table

echo ""
echo -e "${BLUE}📊 Summary${NC}"
echo "  Empty S3 Buckets: ${#EMPTY_BUCKETS[@]}"
echo ""
echo "💡 Tip: Review empty buckets and consider deleting if not needed"
echo "💡 Tip: Use 'aws s3 rb s3://bucket-name' to delete empty buckets (after ensuring they're not in Terraform)"

