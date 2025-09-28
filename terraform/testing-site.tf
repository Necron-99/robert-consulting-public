# Private Testing Site Infrastructure
# Cost-optimized setup for development and testing

# S3 Bucket for Testing Site
resource "aws_s3_bucket" "testing_site" {
  bucket = "robert-consulting-testing-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Testing Site Bucket"
    Environment = "testing"
    Purpose     = "private-testing"
    CostCenter  = "development"
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Versioning (disabled for cost savings)
resource "aws_s3_bucket_versioning" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id
  versioning_configuration {
    status = "Disabled"  # Cost optimization: no versioning
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# CloudFront Distribution for Testing Site
resource "aws_cloudfront_distribution" "testing_site" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.testing_site.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.testing_site.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"  # Cost optimization: HTTP only
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = false  # Cost optimization: disable IPv6
  default_root_object = "index.html"

  # Cost optimization: minimal caching
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.testing_site.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Minimal TTL for testing
    min_ttl     = 0
    default_ttl = 300    # 5 minutes
    max_ttl     = 3600   # 1 hour

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Cost optimization: restrict to specific IPs (optional)
  restrictions {
    geo_restriction {
      restriction_type = "none"  # Allow all locations for testing
    }
  }

  # Cost optimization: minimal price class
  price_class = "PriceClass_100"  # US, Canada, Europe only

  # Viewer certificate (required)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Security headers
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }

  tags = {
    Name        = "Testing Site CloudFront"
    Environment = "testing"
    Purpose     = "private-testing"
    CostCenter  = "development"
  }
}

# Route 53 Record (optional - only if you have a domain)
# Uncomment and configure if you want a custom domain
# resource "aws_route53_record" "testing_site" {
#   zone_id = "YOUR_HOSTED_ZONE_ID"
#   name    = "testing.yourdomain.com"
#   type    = "A"
# 
#   alias {
#     name                   = aws_cloudfront_distribution.testing_site.domain_name
#     zone_id                = aws_cloudfront_distribution.testing_site.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# Cost monitoring and billing alerts
resource "aws_budgets_budget" "testing_site" {
  name         = "testing-site-budget"
  budget_type  = "COST"
  limit_amount = "10"  # $10 monthly limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80  # Alert at 80% of budget
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100  # Alert at 100% of budget
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }
}

# Outputs
output "testing_site_bucket_name" {
  description = "Name of the S3 bucket for testing site"
  value       = aws_s3_bucket.testing_site.bucket
}

output "testing_site_bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.testing_site.website_endpoint
}

output "testing_site_cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.testing_site.domain_name
}

output "testing_site_cloudfront_url" {
  description = "Full URL of the testing site"
  value       = "https://${aws_cloudfront_distribution.testing_site.domain_name}"
}

output "testing_site_cost_estimate" {
  description = "Estimated monthly cost for testing site"
  value = {
    s3_storage = "~$0.50"      # Minimal storage costs
    cloudfront = "~$1.00"      # Minimal CloudFront costs
    route53    = "~$0.50"      # Optional domain costs
    total      = "~$2.00"      # Total estimated monthly cost
  }
}
