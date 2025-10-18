#!/bin/bash

echo "🧹 Infrastructure Cleanup Script"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "terraform/terraform.tfstate" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "📋 Analysis Summary:"
echo "==================="
echo "✅ SAFE TO REMOVE:"
echo "  - Testing site infrastructure (completely unused)"
echo "  - Legacy testing bucket (robert-consulting-testing-site)"
echo ""
echo "⚠️  KEEP (DO NOT REMOVE):"
echo "  - Production site infrastructure"
echo "  - Staging site infrastructure" 
echo "  - Admin site infrastructure"
echo "  - Contact form (Lambda + API Gateway)"
echo "  - SES email service"
echo "  - Route53 DNS"
echo "  - CloudWatch monitoring"
echo "  - WAF security"
echo ""

# Step 1: Remove testing-bucket.tf
echo "🗑️  Step 1: Removing testing-bucket.tf file..."
if [ -f "terraform/testing-bucket.tf" ]; then
    mv terraform/testing-bucket.tf terraform/testing-bucket.tf.backup
    echo "✅ Moved testing-bucket.tf to testing-bucket.tf.backup"
else
    echo "ℹ️  testing-bucket.tf not found (already removed?)"
fi

# Step 2: Show terraform plan
echo ""
echo "📋 Step 2: Running terraform plan to see what will be destroyed..."
cd terraform
terraform plan -destroy -target=aws_s3_bucket.testing_site -target=aws_cloudfront_distribution.testing_site

echo ""
echo "⚠️  IMPORTANT: Review the plan above carefully!"
echo "   Only testing site resources should be listed for destruction."
echo ""

read -p "🤔 Do you want to proceed with removing the testing site infrastructure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing testing site infrastructure..."
    terraform destroy -target=aws_s3_bucket.testing_site -target=aws_cloudfront_distribution.testing_site -auto-approve
    echo "✅ Testing site infrastructure removed"
else
    echo "❌ Cleanup cancelled by user"
    exit 0
fi

# Step 3: Manual bucket cleanup
echo ""
echo "🗑️  Step 3: Manual cleanup of legacy testing bucket..."
echo "   Bucket: robert-consulting-testing-site (78 files)"
echo "   This bucket is not managed by Terraform and must be deleted manually."
echo ""

read -p "🤔 Do you want to delete the legacy testing bucket? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting legacy testing bucket..."
    aws s3 rb s3://robert-consulting-testing-site --force
    echo "✅ Legacy testing bucket deleted"
else
    echo "ℹ️  Legacy testing bucket left intact (can be deleted manually later)"
fi

echo ""
echo "🎉 Cleanup completed!"
echo ""
echo "📊 Summary:"
echo "  ✅ Removed unused testing site infrastructure"
echo "  ✅ Cleaned up legacy testing bucket (if confirmed)"
echo "  ✅ Preserved all active infrastructure"
echo ""
echo "💡 Next steps:"
echo "  1. Verify all workflows still function correctly"
echo "  2. Test staging and production deployments"
echo "  3. Monitor for any issues over the next few days"
