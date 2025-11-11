#!/bin/bash

# Cleanup Duplicate Plex CloudFront Distribution
# Removes the unused E36R64EU3W6DCP distribution

set -e

echo "🧹 CloudFront Distribution Cleanup"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Distribution IDs
ACTIVE_PLEX_DIST="E3T1Z34I8CU20F"  # Has alias plex.robertconsulting.net
UNUSED_PLEX_DIST="E36R64EU3W6DCP"  # No alias - duplicate

echo "📋 Distribution Status:"
echo "----------------------"
echo "Active Plex Distribution: ${GREEN}$ACTIVE_PLEX_DIST${NC} (has alias)"
echo "Unused Plex Distribution: ${RED}$UNUSED_PLEX_DIST${NC} (no alias - to be deleted)"
echo ""

# Verify unused distribution has no alias
echo "🔍 Verifying unused distribution has no alias..."
ALIAS=$(aws cloudfront get-distribution --id "$UNUSED_PLEX_DIST" \
  --query 'Distribution.DistributionConfig.Aliases.Items[0]' \
  --output text 2>/dev/null || echo "None")

if [ "$ALIAS" != "None" ] && [ -n "$ALIAS" ]; then
  echo "${RED}❌ ERROR: Distribution $UNUSED_PLEX_DIST has alias: $ALIAS${NC}"
  echo "   This distribution is NOT unused. Aborting cleanup."
  exit 1
fi

echo "${GREEN}✅ Confirmed: Distribution $UNUSED_PLEX_DIST has no alias${NC}"
echo ""

# Check if in Terraform state
echo "🔍 Checking Terraform state..."
cd terraform

if terraform state list 2>/dev/null | grep -q "module.plex_recommendations.aws_cloudfront_distribution.plex_distribution"; then
  echo "${YELLOW}⚠️  Distribution is in Terraform state${NC}"
  echo ""
  echo "To remove from Terraform:"
  echo "  1. Remove CloudFront distribution from terraform/modules/plex-project/main.tf"
  echo "  2. Run: terraform state rm module.plex_recommendations.aws_cloudfront_distribution.plex_distribution"
  echo "  3. Then delete from AWS (see below)"
  echo ""
else
  echo "${GREEN}✅ Distribution is NOT in Terraform state${NC}"
  echo "   Safe to delete directly from AWS"
  echo ""
fi

# Check request count (last 7 days)
echo "📊 Checking request count (last 7 days)..."
REQUESTS=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value="$UNUSED_PLEX_DIST" \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum \
  --query 'Datapoints[0].Sum' \
  --output text 2>/dev/null || echo "0")

if [ "$REQUESTS" = "0" ] || [ -z "$REQUESTS" ]; then
  echo "${GREEN}✅ No requests in last 7 days - confirmed unused${NC}"
else
  echo "${YELLOW}⚠️  WARNING: $REQUESTS requests in last 7 days${NC}"
  echo "   Review before deleting"
fi

echo ""
echo "🗑️  To delete the unused distribution:"
echo "--------------------------------------"
echo ""
echo "1. Disable the distribution first:"
echo "   aws cloudfront get-distribution-config --id $UNUSED_PLEX_DIST > /tmp/dist-config.json"
echo "   # Edit /tmp/dist-config.json: set Enabled = false"
echo "   aws cloudfront update-distribution --id $UNUSED_PLEX_DIST --if-match <ETag> --distribution-config file:///tmp/dist-config.json"
echo ""
echo "2. Wait for deployment to complete (check status)"
echo ""
echo "3. Delete the distribution:"
echo "   aws cloudfront delete-distribution --id $UNUSED_PLEX_DIST --if-match <ETag>"
echo ""
echo "${YELLOW}⚠️  Note: CloudFront distributions take time to delete.${NC}"
echo "   You must wait for the distribution to be fully disabled before deletion."

