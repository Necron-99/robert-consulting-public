# Terraform Configuration Fixes

## Issues Fixed

### 1. Missing viewer_certificate block
**Error**: `At least 1 "viewer_certificate" blocks are required.`

**Fix**: Added viewer_certificate block to CloudFront distribution:

```hcl
# Viewer certificate (required)
viewer_certificate {
  cloudfront_default_certificate = true
}
```

### 2. Invalid cost_filters argument
**Error**: `An argument named "cost_filters" is not expected here.`

**Fix**: Removed the invalid `cost_filters` block from aws_budgets_budget resource.

## Corrected Configuration

### CloudFront Distribution
```hcl
resource "aws_cloudfront_distribution" "testing_site" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.testing_site.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.testing_site.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.testing_site.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 3600

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  # FIXED: Added required viewer_certificate block
  viewer_certificate {
    cloudfront_default_certificate = true
  }

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
```

### Budget Resource
```hcl
# FIXED: Removed invalid cost_filters argument
resource "aws_budgets_budget" "testing_site" {
  name         = "testing-site-budget"
  budget_type  = "COST"
  limit_amount = "10"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["your-email@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["your-email@example.com"]
  }
}
```

## Usage

1. Apply the corrected Terraform configuration:
   ```bash
   terraform plan
   terraform apply
   ```

2. The testing site will be created with:
   - S3 bucket for static hosting
   - CloudFront distribution with proper SSL certificate
   - Budget alerts for cost monitoring
   - Cost-optimized configuration

## Cost Optimization Features

- **No versioning**: S3 versioning disabled to save costs
- **HTTP-only origin**: CloudFront to S3 communication over HTTP
- **Minimal caching**: Short TTL values for testing
- **Price class 100**: Only US, Canada, Europe edge locations
- **IPv6 disabled**: Reduces complexity and costs
- **Budget alerts**: $10 monthly limit with 80% and 100% notifications

## Estimated Monthly Costs

- S3 Storage: ~$0.50
- CloudFront: ~$1.00
- Route53 (optional): ~$0.50
- **Total**: ~$2.00/month
