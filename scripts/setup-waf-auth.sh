#!/bin/bash
# Script to set up WAF-based authentication for admin site

set -e

echo "🔐 Setting up WAF-based authentication for admin site..."

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
    echo "❌ No IP added. You'll need to manually configure allowed IPs."
    ALLOWED_IPS="[]"
fi

# Create terraform.tfvars file
echo "📝 Creating terraform.tfvars file..."
cat > terraform/admin-waf.tfvars << EOF
# WAF Authentication Configuration
admin_domain_name = "admin.robertconsulting.net"
admin_allowed_ips = $ALLOWED_IPS
existing_route53_zone_id = "Z1D633PJN98FT9"  # robertconsulting.net zone
admin_acm_certificate_arn = "arn:aws:acm:us-east-1:${data.aws_caller_identity.current.account_id}:certificate/bd248f13-f64f-45b0-8ca8-0321c48650da"
EOF

echo "✅ Configuration saved to terraform/admin-waf.tfvars"

# Show next steps
echo ""
echo "🚀 Next steps:"
echo "1. Review the configuration:"
echo "   cat terraform/admin-waf.tfvars"
echo ""
echo "2. Deploy the WAF infrastructure:"
echo "   cd terraform"
echo "   terraform plan -var-file=admin-waf.tfvars -target=aws_wafv2_web_acl.admin"
echo "   terraform apply -var-file=admin-waf.tfvars -target=aws_wafv2_web_acl.admin"
echo ""
echo "3. Update the CloudFront distribution:"
echo "   terraform apply -var-file=admin-waf.tfvars -target=aws_cloudfront_distribution.admin"
echo ""
echo "4. Upload admin site files:"
echo "   aws s3 sync ./admin s3://\$(terraform output -raw admin_bucket) --delete"
echo ""
echo "5. Test access:"
echo "   curl -I https://admin.robertconsulting.net/"
echo ""
echo "💡 To add more IPs later, edit terraform/admin-waf.tfvars and run terraform apply"

# Show current IP for reference
echo "📋 Your current IP for reference: $CURRENT_IP"
