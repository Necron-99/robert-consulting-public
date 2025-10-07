# Client Infrastructure Module
# Reusable module for client-specific infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "client_name" {
  description = "Name of the client"
  type        = string
}

variable "client_domain" {
  description = "Primary domain for the client"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "additional_domains" {
  description = "Additional domains to support"
  type        = list(string)
  default     = []
}

variable "enable_cloudfront" {
  description = "Enable CloudFront CDN"
  type        = bool
  default     = true
}

# If set, adopt an existing CloudFront distribution instead of creating one
variable "existing_cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID to adopt (skip creation if set)"
  type        = string
  default     = null
}

# If set (and creating a new distribution), use this ACM cert ARN and set aliases
variable "existing_acm_certificate_arn" {
  description = "Existing ACM certificate ARN to use for CloudFront (us-east-1)"
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

# If set, adopt an existing Route53 hosted zone instead of creating one
variable "existing_route53_zone_id" {
  description = "Existing Route53 hosted zone ID to adopt (skip creation if set)"
  type        = string
  default     = null
}

# Local values
# Data sources
data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Client      = var.client_name
    Environment = var.environment
    Purpose     = "Web Hosting"
    ManagedBy   = "Robert Consulting"
  }
}

# Optionally adopt an existing CloudFront distribution
data "aws_cloudfront_distribution" "existing" {
  count = var.enable_cloudfront && var.existing_cloudfront_distribution_id != null ? 1 : 0

  id = var.existing_cloudfront_distribution_id
}

# Optionally adopt an existing Route53 hosted zone
data "aws_route53_zone" "existing" {
  count = var.existing_route53_zone_id != null ? 1 : 0

  zone_id = var.existing_route53_zone_id
}

# S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = "${var.client_name}-website-${random_id.bucket_suffix.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.client_name} Website"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# CloudFront distribution (if enabled)
resource "aws_cloudfront_distribution" "website" {
  count = var.enable_cloudfront && var.existing_cloudfront_distribution_id == null ? 1 : 0

  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.website.bucket}"

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

  aliases = var.existing_acm_certificate_arn != null ? concat([var.client_domain], var.additional_domains) : []

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom error pages
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.existing_acm_certificate_arn != null ? [1] : []
    content {
      acm_certificate_arn            = var.existing_acm_certificate_arn
      ssl_support_method             = "sni-only"
      minimum_protocol_version       = "TLSv1.2_2021"
      cloudfront_default_certificate = false
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.existing_acm_certificate_arn == null ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.client_name} CloudFront"
  })
}

# ACM certificate for HTTPS
resource "aws_acm_certificate" "website" {
  count = var.enable_cloudfront && var.existing_cloudfront_distribution_id == null ? 1 : 0

  domain_name       = var.client_domain
  validation_method = "DNS"

  subject_alternative_names = var.additional_domains

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.client_name} SSL Certificate"
  })
}

# Route 53 hosted zone
resource "aws_route53_zone" "website" {
  count = var.existing_route53_zone_id == null ? 1 : 0

  name = var.client_domain

  tags = merge(local.common_tags, {
    Name = "${var.client_name} Hosted Zone"
  })
}

# Route 53 records
resource "aws_route53_record" "website" {
  count = var.enable_cloudfront ? 1 : 0

  zone_id = var.existing_route53_zone_id != null ? data.aws_route53_zone.existing[0].zone_id : aws_route53_zone.website[0].zone_id
  name    = var.client_domain
  type    = "A"

  alias {
    name    = var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].domain_name : aws_cloudfront_distribution.website[0].domain_name
    zone_id = var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].hosted_zone_id : aws_cloudfront_distribution.website[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Additional DNS records for each additional domain (www/app, etc.)
resource "aws_route53_record" "additional" {
  count = var.enable_cloudfront ? length(var.additional_domains) : 0

  zone_id = var.existing_route53_zone_id != null ? data.aws_route53_zone.existing[0].zone_id : aws_route53_zone.website[0].zone_id
  name    = var.additional_domains[count.index]
  type    = "A"

  alias {
    name    = var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].domain_name : aws_cloudfront_distribution.website[0].domain_name
    zone_id = var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].hosted_zone_id : aws_cloudfront_distribution.website[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# WAF Web ACL (if enabled)
resource "aws_wafv2_web_acl" "website" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.client_name}-website-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.client_name}-website-waf"
    sampled_requests_enabled   = true
  }

  # Basic rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.client_name} WAF"
  })
}

# Associate WAF with CloudFront (temporarily disabled due to ARN format issues)
# resource "aws_wafv2_web_acl_association" "website" {
#   count = var.enable_waf && var.enable_cloudfront ? 1 : 0

#   resource_arn = aws_cloudfront_distribution.website[0].arn
#   web_acl_arn  = aws_wafv2_web_acl.website[0].arn
# }

# CloudWatch dashboard (if monitoring enabled)
resource "aws_cloudwatch_dashboard" "website" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = "${var.client_name}-website-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].id : aws_cloudfront_distribution.website[0].id],
            [".", "BytesDownloaded", ".", "."],
            [".", "BytesUploaded", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "CloudFront Metrics"
        }
      }
    ]
  })

  # tags not supported on aws_cloudwatch_dashboard
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  count = var.enable_monitoring ? 1 : 0

  name = "${var.client_name}-alerts"

  tags = merge(local.common_tags, {
    Name = "${var.client_name} Alerts"
  })
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  count = var.enable_monitoring && var.enable_cloudfront ? 1 : 0

  alarm_name          = "${var.client_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors error rate"
  alarm_actions       = [aws_sns_topic.alerts[0].arn]

  dimensions = {
    DistributionId = var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].id : aws_cloudfront_distribution.website[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.client_name} Error Rate Alarm"
  })
}

# Outputs
output "bucket_name" {
  description = "S3 bucket name for website hosting"
  value       = aws_s3_bucket.website.bucket
}

output "bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.enable_cloudfront ? (var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].id : aws_cloudfront_distribution.website[0].id) : null
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.enable_cloudfront ? (var.existing_cloudfront_distribution_id != null ? data.aws_cloudfront_distribution.existing[0].domain_name : aws_cloudfront_distribution.website[0].domain_name) : null
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = var.existing_route53_zone_id != null ? data.aws_route53_zone.existing[0].zone_id : aws_route53_zone.website[0].zone_id
}

output "route53_name_servers" {
  description = "Route 53 name servers"
  value       = var.existing_route53_zone_id != null ? data.aws_route53_zone.existing[0].name_servers : aws_route53_zone.website[0].name_servers
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enable_waf ? aws_wafv2_web_acl.website[0].arn : null
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = var.enable_monitoring ? aws_sns_topic.alerts[0].arn : null
}
