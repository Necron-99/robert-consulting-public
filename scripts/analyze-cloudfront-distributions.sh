#!/bin/bash

# Analyze CloudFront Distributions
# Identifies duplicates, unused distributions, and provides cleanup recommendations

set -e

echo "🔍 CloudFront Distribution Analysis"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get all distributions
echo "📋 Fetching all CloudFront distributions..."
DISTRIBUTIONS=$(aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,DomainName,Comment,Aliases.Items[0],Status]" --output text)

echo ""
echo "Found distributions:"
echo "-------------------"

# Process distributions
echo "$DISTRIBUTIONS" | while IFS=$'\t' read -r id domain comment alias status; do
  echo ""
  echo "ID: $id"
  echo "  Domain: $domain"
  echo "  Comment: ${comment:-'(none)'}"
  echo "  Alias: ${alias:-'(none)'}"
  echo "  Status: $status"
  
  # Check if in Terraform state
  if terraform state list 2>/dev/null | grep -q "cloudfront_distribution.*$id"; then
    echo "  ${GREEN}✅ Managed by Terraform${NC}"
  else
    echo "  ${YELLOW}⚠️  NOT in Terraform state${NC}"
  fi
done

echo ""
echo "📊 Summary:"
echo "----------"

# Check for duplicates by checking aliases
ALIASES=$(echo "$DISTRIBUTIONS" | cut -f4 | grep -v "^$" | sort | uniq -d)
if [ -n "$ALIASES" ]; then
  echo "${RED}❌ Duplicate aliases found:${NC}"
  echo "$ALIASES" | while read alias; do
    echo "  - $alias"
  done
else
  echo "${GREEN}✅ No duplicate aliases found${NC}"
fi

# Check for unused distributions (no alias, no recent requests)
echo ""
echo "🔍 Checking for unused distributions..."
echo ""

# Get request counts from CloudWatch (last 7 days)
for id in $(echo "$DISTRIBUTIONS" | cut -f1); do
  alias=$(echo "$DISTRIBUTIONS" | grep "^$id" | cut -f4)
  
  if [ -z "$alias" ]; then
    # No alias - check request count
    requests=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/CloudFront \
      --metric-name Requests \
      --dimensions Name=DistributionId,Value=$id \
      --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
      --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
      --period 86400 \
      --statistics Sum \
      --query 'Datapoints[0].Sum' \
      --output text 2>/dev/null || echo "0")
    
    if [ "$requests" = "0" ] || [ -z "$requests" ]; then
      echo "${YELLOW}⚠️  Distribution $id has no alias and no requests in last 7 days${NC}"
      echo "   Consider removing if unused"
    fi
  fi
done

echo ""
echo "✅ Analysis complete!"

