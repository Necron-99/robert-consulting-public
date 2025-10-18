#!/bin/bash
echo "=== DELETING DUPLICATE CLOUDFRONT DISTRIBUTION ==="
echo "Checking status of distribution E1JE597A8ZZ547..."

# Check if distribution is disabled
STATUS=$(aws cloudfront get-distribution --id E1JE597A8ZZ547 --query 'Distribution.Status' --output text 2>/dev/null)
ENABLED=$(aws cloudfront get-distribution --id E1JE597A8ZZ547 --query 'Distribution.DistributionConfig.Enabled' --output text 2>/dev/null)

echo "Status: $STATUS"
echo "Enabled: $ENABLED"

if [ "$STATUS" = "Deployed" ] && [ "$ENABLED" = "False" ]; then
    echo "✅ Distribution is fully disabled, proceeding with deletion..."
    ETAG=$(aws cloudfront get-distribution --id E1JE597A8ZZ547 --query 'ETag' --output text)
    aws cloudfront delete-distribution --id E1JE597A8ZZ547 --if-match $ETAG
    echo "✅ Duplicate CloudFront distribution deleted!"
else
    echo "⏳ Distribution still disabling, please wait and run this script again in a few minutes"
fi
