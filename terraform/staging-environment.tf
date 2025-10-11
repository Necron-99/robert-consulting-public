# Staging Environment Configuration
# Mirrors production infrastructure with restricted access and minimal costs

# Variables for staging environment
variable "staging_domain_name" {
  description = "Domain name for staging environment"
  type        = string
  default     = "staging.robertconsulting.net"
}

variable "staging_allowed_ips" {
  description = "List of IP addresses allowed to access staging environment"
  type        = list(string)
  default     = [
    # Add your IP addresses here for restricted access
    # "1.2.3.4/32",  # Example: Your home IP
    # "5.6.7.8/32",  # Example: Your office IP
  ]
}

# S3 bucket for staging website hosting
resource "aws_s3_bucket" "staging_website_bucket" {
  bucket = "robert-consulting-staging-website"
  
  tags = {
    Name        = "Robert Consulting Staging Website"
    Environment = "Staging"
    Purpose     = "Staging Website Hosting"
    ManagedBy   = "Terraform"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "staging_website_bucket" {
  bucket = aws_s3_bucket.staging_website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "staging_website_bucket" {
  bucket = aws_s3_bucket.staging_website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block (allow public policies for website)
resource "aws_s3_bucket_public_access_block" "staging_website_bucket" {
  bucket = aws_s3_bucket.staging_website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "staging_website_bucket" {
  bucket = aws_s3_bucket.staging_website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for public read access (same as production)
resource "aws_s3_bucket_policy" "staging_website_bucket" {
  bucket = aws_s3_bucket.staging_website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.staging_website_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront response headers policy for staging (identical to production)
resource "aws_cloudfront_response_headers_policy" "staging_security_headers" {
  name = "staging-security-headers-policy"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://*.amazonaws.com; object-src 'none'; base-uri 'self'; frame-src 'none'; frame-ancestors 'none'; upgrade-insecure-requests; block-all-mixed-content;"
      override                 = false
    }
    content_type_options {
      override = false
    }
    frame_options {
      frame_option = "DENY"
      override     = false
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = false
    }
    x_xss_protection {
      mode     = "block"
      override = false
      protection = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
      override = false
    }
    items {
      header   = "Cross-Origin-Embedder-Policy"
      value    = "require-corp"
      override = false
    }
    items {
      header   = "Cross-Origin-Opener-Policy"
      value    = "same-origin"
      override = false
    }
    items {
      header   = "Cross-Origin-Resource-Policy"
      value    = "same-origin"
      override = false
    }
    items {
      header   = "X-DNS-Prefetch-Control"
      value    = "off"
      override = false
    }
    items {
      header   = "X-Download-Options"
      value    = "noopen"
      override = false
    }
    items {
      header   = "X-Permitted-Cross-Domain-Policies"
      value    = "none"
      override = false
    }
  }

  # Remove server headers to prevent information disclosure
  remove_headers_config {
    items {
      header = "Server"
    }
    items {
      header = "X-Powered-By"
    }
    items {
      header = "X-AspNet-Version"
    }
    items {
      header = "X-AspNetMvc-Version"
    }
  }
}

# CloudFront distribution for staging (identical to production)
resource "aws_cloudfront_distribution" "staging_website" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.staging_website_bucket.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.staging_website_bucket.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Custom domain and SSL certificate
  aliases = [var.staging_domain_name]

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.staging_website_bucket.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Apply security headers policy (identical to production)
    response_headers_policy_id = aws_cloudfront_response_headers_policy.staging_security_headers.id

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Cost optimization: Use PriceClass_100 (US, Canada, Europe)
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate for staging domain
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.staging_ssl_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name        = "Robert Consulting Staging Website"
    Environment = "Staging"
    Purpose     = "Staging Website CDN"
    ManagedBy   = "Terraform"
  }
}

# SSL certificate for staging domain
resource "aws_acm_certificate" "staging_ssl_cert" {
  provider = aws.us_east_1  # CloudFront requires certificates in us-east-1

  domain_name       = var.staging_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Staging SSL Certificate"
    Environment = "Staging"
    Purpose     = "SSL Certificate for Staging"
    ManagedBy   = "Terraform"
  }
}

# DNS validation for SSL certificate
resource "aws_route53_record" "staging_ssl_validation" {
  for_each = {
    for dvo in aws_acm_certificate.staging_ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# SSL certificate validation
resource "aws_acm_certificate_validation" "staging_ssl_cert" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.staging_ssl_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.staging_ssl_validation : record.fqdn]
}

# Route53 record for staging domain
resource "aws_route53_record" "staging_domain" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.staging_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.staging_website.domain_name
    zone_id                = aws_cloudfront_distribution.staging_website.hosted_zone_id
    evaluate_target_health = false
  }
}

# WAF Web ACL for staging (restricted access)
resource "aws_wafv2_web_acl" "staging_waf" {
  name  = "staging-website-waf"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  # IP-based access control (restrict to allowed IPs)
  rule {
    name     = "AllowSpecificIPs"
    priority = 1

    override_action {
      none {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.staging_allowed_ips.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowSpecificIPs"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting (same as production)
  rule {
    name     = "RateLimit"
    priority = 2

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # Block suspicious user agents (same as production)
  rule {
    name     = "BlockSuspiciousUserAgents"
    priority = 3

    override_action {
      none {}
    }

    statement {
      byte_match_statement {
        search_string         = "sqlmap"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockSuspiciousUserAgents"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "StagingWebsiteWAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "Staging Website WAF"
    Environment = "Staging"
    Purpose     = "WAF Protection for Staging"
    ManagedBy   = "Terraform"
  }
}

# IP set for allowed IPs (restrict access)
resource "aws_wafv2_ip_set" "staging_allowed_ips" {
  name               = "staging-allowed-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.staging_allowed_ips

  tags = {
    Name        = "Staging Allowed IPs"
    Environment = "Staging"
    Purpose     = "IP Access Control for Staging"
    ManagedBy   = "Terraform"
  }
}

# Associate WAF with CloudFront distribution
resource "aws_wafv2_web_acl_association" "staging_waf_association" {
  resource_arn = aws_cloudfront_distribution.staging_website.arn
  web_acl_arn  = aws_wafv2_web_acl.staging_waf.arn
}

# CloudWatch alarms for staging (minimal monitoring)
resource "aws_cloudwatch_metric_alarm" "staging_high_error_rate" {
  alarm_name          = "staging-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors staging site 4xx error rate"
  alarm_actions       = [aws_sns_topic.staging_alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.staging_website.id
    Region         = "Global"
  }

  tags = {
    Name        = "Staging High Error Rate"
    Environment = "Staging"
    Purpose     = "Monitor Staging Error Rate"
    ManagedBy   = "Terraform"
  }
}

# SNS topic for staging alerts
resource "aws_sns_topic" "staging_alerts" {
  name = "staging-security-alerts"

  tags = {
    Name        = "Staging Security Alerts"
    Environment = "Staging"
    Purpose     = "Staging Security Notifications"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "staging_bucket_name" {
  description = "Name of the staging S3 bucket"
  value       = aws_s3_bucket.staging_website_bucket.bucket
}

output "staging_cloudfront_url" {
  description = "CloudFront URL for the staging site"
  value       = "https://${aws_cloudfront_distribution.staging_website.domain_name}"
}

output "staging_domain_url" {
  description = "Custom domain URL for the staging site"
  value       = "https://${var.staging_domain_name}"
}

output "staging_waf_arn" {
  description = "ARN of the staging WAF Web ACL"
  value       = aws_wafv2_web_acl.staging_waf.arn
}
