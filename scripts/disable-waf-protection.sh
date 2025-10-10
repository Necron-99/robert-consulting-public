#!/bin/bash
# Script to disable WAF protection for the admin site

set -e

echo "🛡️  Disabling WAF protection for admin site..."

# Update terraform.tfvars to disable WAF
echo "📝 Updating WAF configuration..."
cat > terraform/admin-waf.tfvars << EOF
# WAF Protection Configuration
admin_waf_enabled = false
admin_allowed_ips = []
EOF

echo "✅ Configuration updated to disable WAF"

# Remove WAF from CloudFront distribution
echo "🔄 Removing WAF from CloudFront distribution..."

# Get current distribution config
aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'DistributionConfig' --output json > /tmp/dist_config.json

# Remove WAF association
jq '.WebACLId = ""' /tmp/dist_config.json > /tmp/no_waf_config.json

# Get current ETag
ETAG=$(aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'ETag' --output text)

# Update distribution
aws cloudfront update-distribution --id E1JE597A8ZZ547 --distribution-config file:///tmp/no_waf_config.json --if-match "$ETAG"

echo "✅ WAF removed from CloudFront distribution!"

# Create invalidation
echo "🔄 Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id E1JE597A8ZZ547 --paths "/*" --query 'Invalidation.Id' --output text)
echo "✅ Invalidation created: $INVALIDATION_ID"

# Cleanup temp files
rm -f /tmp/dist_config.json /tmp/no_waf_config.json

echo ""
echo "🎉 WAF protection has been disabled!"
echo "🌐 Admin site is now accessible without WAF restrictions"
echo "🔐 Client-side authentication is still active"
echo ""
echo "📋 Current protection:"
echo "   - ✅ Client-side authentication (admin/CHEQZvqKHsh9EyKv4ict)"
echo "   - ❌ WAF protection (disabled)"
echo "   - ✅ HTTPS encryption"
echo "   - ✅ CloudFront caching"
