#!/bin/bash
# Script to switch between different admin authentication methods

set -e

AUTH_METHOD=$1
ADMIN_DISTRIBUTION_ID="E1JE597A8ZZ547"

if [ -z "$AUTH_METHOD" ]; then
    echo "Usage: $0 <basic|cognito|none>"
    echo ""
    echo "Options:"
    echo "  basic   - Enable CloudFront Function Basic Auth (current working method)"
    echo "  cognito - Enable Cognito authentication (requires deployment)"
    echo "  none    - Disable authentication (open access)"
    exit 1
fi

echo "Switching admin authentication to: $AUTH_METHOD"

case $AUTH_METHOD in
    "basic")
        echo "Enabling CloudFront Function Basic Auth..."
        
        # Get current distribution config
        aws cloudfront get-distribution-config --id "$ADMIN_DISTRIBUTION_ID" --query 'DistributionConfig' --output json > /tmp/dist_config.json
        
        # Add function association for basic auth
        jq '.DefaultCacheBehavior.FunctionAssociations = {"Quantity": 1, "Items": [{"FunctionARN": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:function/rc-admin-basic-auth-fixed", "EventType": "viewer-request"}]}' /tmp/dist_config.json > /tmp/with_auth_config.json
        
        # Get current ETag
        ETAG=$(aws cloudfront get-distribution-config --id "$ADMIN_DISTRIBUTION_ID" --query 'ETag' --output text)
        
        # Update distribution
        aws cloudfront update-distribution --id "$ADMIN_DISTRIBUTION_ID" --distribution-config file:///tmp/with_auth_config.json --if-match "$ETAG"
        
        echo "✅ Basic Auth enabled"
        echo "📝 Credentials:"
        echo "   Username: admin"
        echo "   Password: CHEQZvqKHsh9EyKv4ict"
        ;;
        
    "cognito")
        echo "Enabling Cognito authentication..."
        echo "⚠️  This requires deploying the Cognito infrastructure first."
        echo "   Run: cd terraform && terraform apply -target=aws_cognito_user_pool.admin"
        echo "   Then re-run this script with 'cognito' option."
        
        # For now, just show the instructions
        echo ""
        echo "📋 Cognito deployment steps:"
        echo "1. Deploy Cognito User Pool"
        echo "2. Create admin user"
        echo "3. Deploy Lambda@Edge function"
        echo "4. Update CloudFront distribution"
        echo "5. Upload admin site files"
        ;;
        
    "none")
        echo "Disabling authentication (open access)..."
        
        # Get current distribution config
        aws cloudfront get-distribution-config --id "$ADMIN_DISTRIBUTION_ID" --query 'DistributionConfig' --output json > /tmp/dist_config.json
        
        # Remove function associations
        jq '.DefaultCacheBehavior.FunctionAssociations = {"Quantity": 0, "Items": []}' /tmp/dist_config.json > /tmp/no_auth_config.json
        
        # Get current ETag
        ETAG=$(aws cloudfront get-distribution-config --id "$ADMIN_DISTRIBUTION_ID" --query 'ETag' --output text)
        
        # Update distribution
        aws cloudfront update-distribution --id "$ADMIN_DISTRIBUTION_ID" --distribution-config file:///tmp/no_auth_config.json --if-match "$ETAG"
        
        echo "✅ Authentication disabled - site is now open"
        ;;
        
    *)
        echo "❌ Invalid authentication method: $AUTH_METHOD"
        echo "Valid options: basic, cognito, none"
        exit 1
        ;;
esac

# Create invalidation
echo "Creating CloudFront invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id "$ADMIN_DISTRIBUTION_ID" --paths "/*" --query 'Invalidation.Id' --output text)
echo "✅ Invalidation created: $INVALIDATION_ID"

echo ""
echo "🔄 Changes will take 5-15 minutes to propagate globally."
echo "🌐 Test at: https://admin.robertconsulting.net"

# Cleanup temp files
rm -f /tmp/dist_config.json /tmp/with_auth_config.json /tmp/no_auth_config.json
