# Cleanup Plan for Unused Infrastructure Resources
# This file documents resources that can be safely removed

# UNUSED RESOURCES TO REMOVE:
# 1. Testing Site Infrastructure (completely unused)
#    - aws_s3_bucket.testing_site
#    - aws_s3_bucket_versioning.testing_site  
#    - aws_s3_bucket_server_side_encryption_configuration.testing_site
#    - aws_s3_bucket_public_access_block.testing_site
#    - aws_s3_bucket_website_configuration.testing_site
#    - aws_s3_bucket_policy.testing_site
#    - aws_cloudfront_distribution.testing_site
#    - All related outputs

# 2. Legacy Testing Bucket (robert-consulting-testing-site)
#    - This bucket exists but is not managed by Terraform
#    - Contains 78 files from October 12th
#    - Can be manually deleted via AWS Console or CLI

# RESOURCES TO KEEP (DO NOT REMOVE):
# - Production: robert-consulting-website + CloudFront
# - Staging: robert-consulting-staging-website + CloudFront  
# - Admin: robert-consulting-admin + CloudFront
# - Contact Form: Lambda + API Gateway
# - SES: Email service
# - Route53: DNS management
# - CloudWatch: Monitoring
# - WAF: Security protection

# CLEANUP STEPS:
# 1. Remove testing-bucket.tf file
# 2. Run: terraform plan to see what will be destroyed
# 3. Run: terraform apply to remove unused resources
# 4. Manually delete robert-consulting-testing-site bucket
# 5. Verify no workflows or processes are affected
