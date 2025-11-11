#!/bin/bash

# Delete the duplicate Plex CloudFront distribution (E36R64EU3W6DCP)
# This script waits for the distribution to be fully deployed after disabling, then deletes it

set -e

DIST_ID="E36R64EU3W6DCP"

echo "🗑️  Deleting Duplicate Plex CloudFront Distribution: $DIST_ID"
echo "=============================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check current status
STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" \
  --query 'Distribution.Status' \
  --output text 2>/dev/null || echo "NotFound")

ENABLED=$(aws cloudfront get-distribution --id "$DIST_ID" \
  --query 'Distribution.DistributionConfig.Enabled' \
  --output text 2>/dev/null || echo "false")

if [ "$STATUS" = "NotFound" ]; then
  echo "${GREEN}✅ Distribution already deleted${NC}"
  exit 0
fi

echo "Current Status: $STATUS"
echo "Enabled: $ENABLED"
echo ""

# If not disabled, disable it first
if [ "$ENABLED" = "true" ]; then
  echo "${YELLOW}⚠️  Distribution is still enabled. Disabling...${NC}"
  
  ETAG=$(aws cloudfront get-distribution-config --id "$DIST_ID" \
    --query 'ETag' \
    --output text)
  
  aws cloudfront get-distribution-config --id "$DIST_ID" \
    --query 'DistributionConfig' > /tmp/dist-config.json
  
  jq '.Enabled = false' /tmp/dist-config.json > /tmp/dist-config-disabled.json
  
  aws cloudfront update-distribution \
    --id "$DIST_ID" \
    --if-match "$ETAG" \
    --distribution-config file:///tmp/dist-config-disabled.json \
    > /dev/null
  
  echo "${GREEN}✅ Distribution disabled${NC}"
  echo ""
fi

# Wait for deployment to complete
echo "${YELLOW}⏳ Waiting for distribution to be fully deployed (this may take 10-15 minutes)...${NC}"
echo "   Checking status every 30 seconds..."
echo ""

MAX_WAIT=1800  # 30 minutes max
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
  STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" \
    --query 'Distribution.Status' \
    --output text 2>/dev/null || echo "Deployed")
  
  if [ "$STATUS" = "Deployed" ]; then
    echo "${GREEN}✅ Distribution is fully deployed and ready for deletion${NC}"
    break
  fi
  
  echo "   Status: $STATUS (elapsed: ${ELAPSED}s)"
  sleep 30
  ELAPSED=$((ELAPSED + 30))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo "${RED}❌ Timeout waiting for deployment. Please check manually.${NC}"
  exit 1
fi

echo ""

# Delete the distribution
echo "🗑️  Deleting distribution..."
FINAL_ETAG=$(aws cloudfront get-distribution-config --id "$DIST_ID" \
  --query 'ETag' \
  --output text)

aws cloudfront delete-distribution \
  --id "$DIST_ID" \
  --if-match "$FINAL_ETAG" \
  > /dev/null

echo "${GREEN}✅ Distribution deletion initiated${NC}"
echo ""
echo "${YELLOW}⚠️  Note: CloudFront distributions can take additional time to fully delete.${NC}"
echo "   The distribution will be completely removed once deletion completes."

# Cleanup
rm -f /tmp/dist-config.json /tmp/dist-config-disabled.json

echo ""
echo "✅ Process complete!"

