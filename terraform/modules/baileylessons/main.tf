# Bailey Lessons Infrastructure Module
# This module manages the baileylessons.com educational platform

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Variables
variable "client_name" {
  description = "Client name for resource naming"
  type        = string
  default     = "baileylessons"
}

variable "client_domain" {
  description = "Primary domain name"
  type        = string
  default     = "baileylessons.com"
}

variable "additional_domains" {
  description = "Additional domains to support"
  type        = list(string)
  default     = ["www.baileylessons.com", "app.baileylessons.com"]
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "existing_cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID to adopt"
  type        = string
  default     = "E23X7BS3VXFFFZ"
}

variable "existing_route53_zone_id" {
  description = "Existing Route53 zone ID"
  type        = string
  default     = "Z01009052GCOJI1M2TTF7"
}

variable "admin_basic_auth_username" {
  description = "Username for Basic Auth to access the admin site"
  type        = string
  default     = "bailey_admin"
}

variable "admin_basic_auth_password" {
  description = "Password for Basic Auth to access the admin site"
  type        = string
  sensitive   = true
  default     = "BaileySecure2025!"
}

# Local tags for consistent naming
locals {
  client_tags = {
    Client      = "Bailey Lessons"
    Environment = var.environment
    Purpose     = "Educational Platform"
    ManagedBy   = "Robert Consulting"
  }

  admin_tags = merge(local.client_tags, {
    Project = "BaileyLessons"
    Purpose = "Admin UI"
  })
}

# Additional variable for certificate handling
variable "create_certificate" {
  description = "Whether to create or use existing ACM certificate"
  type        = bool
  default     = false
}

# Random ID for unique naming
resource "random_id" "admin_suffix" {
  byte_length = 3
}

# Get existing ACM certificate for baileylessons.com
# Note: This certificate exists in the baileylessons account (737915157697)
# and should be managed separately from the main account infrastructure
# Disabled for now since certificate is in different account
# data "aws_acm_certificate" "baileylessons" {
#   count    = var.create_certificate ? 0 : 1
#   domain   = var.client_domain
#   statuses = ["ISSUED", "PENDING_VALIDATION"]
# }

# S3 Bucket for admin site
resource "aws_s3_bucket" "admin" {
  bucket = "${var.client_name}-admin-${random_id.admin_suffix.hex}"

  tags = merge(local.admin_tags, { Name = "BaileyLessonsAdmin" })
}

# S3 bucket security configurations
resource "aws_s3_bucket_public_access_block" "admin" {
  bucket = aws_s3_bucket.admin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "admin" {
  bucket = aws_s3_bucket.admin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "admin" {
  bucket = aws_s3_bucket.admin.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "admin" {
  name                              = "${var.client_name}-admin-oac-${random_id.admin_suffix.hex}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_s3_bucket" "admin" {
  bucket = aws_s3_bucket.admin.bucket
}

# S3 Bucket Policy for CloudFront access
resource "aws_s3_bucket_policy" "admin" {
  bucket = aws_s3_bucket.admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.admin.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.admin.arn
          }
        }
      }
    ]
  })
}

# CloudFront Function for Basic Auth
locals {
  cf_function_code = <<EOT
function handler(event) {
  var req = event.request;
  var headers = req.headers;

  var authHeader = headers.authorization && headers.authorization.value;
  var expected = 'Basic ${base64encode("${var.admin_basic_auth_username}:${var.admin_basic_auth_password}")}';

  if (!authHeader || authHeader !== expected) {
    return {
      statusCode: 401,
      statusDescription: 'Unauthorized',
      headers: { 'www-authenticate': { value: 'Basic realm="Bailey Lessons Admin"' } },
      body: 'Authentication required'
    };
  }
  return req;
}
EOT
}

resource "aws_cloudfront_function" "basic_auth" {
  name    = "${var.client_name}-admin-basic-auth-${random_id.admin_suffix.hex}"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = local.cf_function_code
}

# CloudFront Distribution for Admin Site
resource "aws_cloudfront_distribution" "admin" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Bailey Lessons Admin Site"
  default_root_object = "index.html"

  aliases = ["admin.${var.client_domain}"]

  origin {
    domain_name = data.aws_s3_bucket.admin.bucket_regional_domain_name
    origin_id   = "s3-admin-${aws_s3_bucket.admin.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.admin.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-admin-${aws_s3_bucket.admin.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.admin_tags
}

# Route53 Record for admin subdomain
resource "aws_route53_record" "admin" {
  zone_id = var.existing_route53_zone_id
  name    = "admin.${var.client_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.admin.domain_name
    zone_id                = aws_cloudfront_distribution.admin.hosted_zone_id
    evaluate_target_health = false
  }
}

# Outputs
output "admin_bucket" {
  value       = aws_s3_bucket.admin.bucket
  description = "S3 bucket name for the Bailey Lessons admin site"
}

output "admin_distribution_domain" {
  value       = aws_cloudfront_distribution.admin.domain_name
  description = "CloudFront domain for the Bailey Lessons admin site"
}

output "admin_url" {
  value       = "https://admin.${var.client_domain}"
  description = "URL to access the Bailey Lessons admin site"
}

output "admin_credentials" {
  value = {
    username = var.admin_basic_auth_username
    password = var.admin_basic_auth_password
  }
  description = "Admin site credentials"
  sensitive   = true
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.admin.id
  description = "CloudFront distribution ID for admin site"
}

output "route53_zone_id" {
  value       = var.existing_route53_zone_id
  description = "Route53 zone ID for baileylessons.com"
}
