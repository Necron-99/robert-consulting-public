#!/bin/bash
# Script to enable WAF protection for the existing admin site

set -e

echo "🛡️  Setting up WAF protection for admin site..."

# Get current public IP
echo "📡 Getting your current public IP address..."
CURRENT_IP=$(curl -s https://ipinfo.io/ip)
echo "Your current IP: $CURRENT_IP"

# Ask if user wants to add this IP
read -p "Add this IP to the allowed list? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ALLOWED_IPS="[\"$CURRENT_IP\"]"
    echo "✅ IP $CURRENT_IP will be added to allowed list"
else
    echo "❌ No IP added. WAF will block all traffic by default."
    ALLOWED_IPS="[]"
fi

# Create terraform.tfvars file for WAF
echo "📝 Creating WAF configuration..."
cat > terraform/admin-waf.tfvars << EOF
# WAF Protection Configuration
admin_waf_enabled = true
admin_allowed_ips = $ALLOWED_IPS
EOF

echo "✅ Configuration saved to terraform/admin-waf.tfvars"

# Deploy WAF
echo "🚀 Deploying WAF protection..."
cd terraform

echo "📋 Planning WAF deployment..."
terraform plan -var-file=admin-waf.tfvars -target=aws_wafv2_web_acl.admin_protection

read -p "Deploy WAF protection? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Applying WAF configuration..."
    terraform apply -var-file=admin-waf.tfvars -target=aws_wafv2_web_acl.admin_protection
    
    echo "✅ WAF deployed successfully!"
    
    # Get WAF ARN
    WAF_ARN=$(terraform output -raw waf_web_acl_arn)
    echo "🛡️  WAF ARN: $WAF_ARN"
    
    echo ""
    echo "⚠️  IMPORTANT: You need to associate the WAF with your CloudFront distribution."
    echo "   This requires updating the CloudFront distribution configuration."
    echo ""
    echo "📋 Next steps:"
    echo "1. Update CloudFront distribution to use WAF:"
    echo "   aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'DistributionConfig' --output json > /tmp/dist_config.json"
    echo "   jq '.WebACLId = \"$WAF_ARN\"' /tmp/dist_config.json > /tmp/with_waf_config.json"
    echo "   ETAG=\$(aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'ETag' --output text)"
    echo "   aws cloudfront update-distribution --id E1JE597A8ZZ547 --distribution-config file:///tmp/with_waf_config.json --if-match \$ETAG"
    echo ""
    echo "2. Create invalidation:"
    echo "   aws cloudfront create-invalidation --distribution-id E1JE597A8ZZ547 --paths '/*'"
    echo ""
    echo "3. Test access:"
    echo "   curl -I https://admin.robertconsulting.net/"
    
    # Offer to do the CloudFront update automatically
    read -p "Update CloudFront distribution automatically? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Updating CloudFront distribution..."
        
        # Get current distribution config
        aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'DistributionConfig' --output json > /tmp/dist_config.json
        
        # Add WAF association
        jq ".WebACLId = \"$WAF_ARN\"" /tmp/dist_config.json > /tmp/with_waf_config.json
        
        # Get current ETag
        ETAG=$(aws cloudfront get-distribution-config --id E1JE597A8ZZ547 --query 'ETag' --output text)
        
        # Update distribution
        aws cloudfront update-distribution --id E1JE597A8ZZ547 --distribution-config file:///tmp/with_waf_config.json --if-match "$ETAG"
        
        echo "✅ CloudFront distribution updated with WAF protection!"
        
        # Create invalidation
        echo "🔄 Creating CloudFront invalidation..."
        INVALIDATION_ID=$(aws cloudfront create-invalidation --distribution-id E1JE597A8ZZ547 --paths "/*" --query 'Invalidation.Id' --output text)
        echo "✅ Invalidation created: $INVALIDATION_ID"
        
        echo ""
        echo "🎉 WAF protection is now active!"
        echo "🛡️  Your admin site is protected by AWS WAF"
        echo "🌐 Test at: https://admin.robertconsulting.net"
        echo ""
        echo "📊 WAF Features:"
        echo "   - IP whitelist protection"
        echo "   - Rate limiting (2000 requests/hour per IP)"
        echo "   - Common attack protection"
        echo "   - SQL injection protection"
        echo "   - Known bad inputs blocking"
        
        # Cleanup temp files
        rm -f /tmp/dist_config.json /tmp/with_waf_config.json
    fi
else
    echo "❌ WAF deployment cancelled"
fi

cd ..

echo ""
echo "📋 Your current IP for reference: $CURRENT_IP"
echo "💡 To add more IPs later, edit terraform/admin-waf.tfvars and run terraform apply"
