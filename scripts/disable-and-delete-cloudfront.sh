#!/bin/bash

# Disable and Delete CloudFront Distribution
# Usage: ./scripts/disable-and-delete-cloudfront.sh <DISTRIBUTION_ID>

set -e

DIST_ID="${1:-E36R64EU3W6DCP}"

if [ -z "$DIST_ID" ]; then
  echo "❌ Error: Distribution ID required"
  echo "Usage: $0 <DISTRIBUTION_ID>"
  exit 1
fi

echo "🗑️  Disabling and Deleting CloudFront Distribution: $DIST_ID"
echo "=========================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Step 1: Get current distribution config
echo "📋 Step 1: Fetching distribution configuration..."
CONFIG_FILE="/tmp/cloudfront-${DIST_ID}-config.json"
ETAG=$(aws cloudfront get-distribution-config --id "$DIST_ID" \
  --query 'ETag' \
  --output text)

aws cloudfront get-distribution-config --id "$DIST_ID" \
  --query 'DistributionConfig' \
  > "$CONFIG_FILE"

echo "${GREEN}✅ Configuration fetched${NC}"
echo ""

# Step 2: Disable the distribution
echo "🛑 Step 2: Disabling distribution..."
jq '.Enabled = false' "$CONFIG_FILE" > "${CONFIG_FILE}.disabled"

DISABLED_ETAG=$(aws cloudfront update-distribution \
  --id "$DIST_ID" \
  --if-match "$ETAG" \
  --distribution-config "file://${CONFIG_FILE}.disabled" \
  --query 'ETag' \
  --output text)

echo "${GREEN}✅ Distribution disabled${NC}"
echo "${YELLOW}⚠️  Waiting for deployment to complete...${NC}"
echo ""

# Step 3: Wait for deployment
echo "⏳ Step 3: Waiting for deployment (this may take 10-15 minutes)..."
while true; do
  STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" \
    --query 'Distribution.Status' \
    --output text 2>/dev/null || echo "Deployed")
  
  if [ "$STATUS" = "Deployed" ]; then
    echo "${GREEN}✅ Distribution is fully deployed${NC}"
    break
  fi
  
  echo "   Status: $STATUS (waiting...)"
  sleep 30
done

echo ""

# Step 4: Get final ETag and delete
echo "🗑️  Step 4: Deleting distribution..."
FINAL_ETAG=$(aws cloudfront get-distribution-config --id "$DIST_ID" \
  --query 'ETag' \
  --output text)

aws cloudfront delete-distribution \
  --id "$DIST_ID" \
  --if-match "$FINAL_ETAG"

echo "${GREEN}✅ Distribution deletion initiated${NC}"
echo ""
echo "${YELLOW}⚠️  Note: CloudFront distributions can take time to fully delete.${NC}"
echo "   The distribution will be removed once deletion completes."

# Cleanup
rm -f "$CONFIG_FILE" "${CONFIG_FILE}.disabled"

echo ""
echo "✅ Process complete!"

