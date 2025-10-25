# Main Site Infrastructure Module
# This module manages the core robertconsulting.net website

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }
}

# Variables
variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "robertconsulting.net"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "response_headers_policy_id" {
  description = "CloudFront response headers policy ID"
  type        = string
}

# S3 Bucket for main website
resource "aws_s3_bucket" "website" {
  bucket = "robert-consulting-website"
  
  tags = {
    Name        = "Robert Consulting Website"
    Environment = "Production"
    Purpose     = "Static Website Hosting"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block (allow public policies for website)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy       = false
  ignore_public_acls        = false
  restrict_public_buckets    = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# CloudFront Distribution for main website
resource "aws_cloudfront_distribution" "website" {
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

    # Security headers
    response_headers_policy_id = var.response_headers_policy_id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [var.domain_name, "www.${var.domain_name}"]

  tags = {
    Name        = "Robert Consulting Website CDN"
    Environment = "Production"
    Purpose     = "Content Delivery"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Staging Environment Resources

# S3 Bucket for staging website
resource "aws_s3_bucket" "staging_website" {
  bucket = "robert-consulting-staging-website"
  
  tags = {
    Name        = "Staging Website"
    Environment = "Staging"
    Purpose     = "Staging Website Hosting"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning for staging
resource "aws_s3_bucket_versioning" "staging_website" {
  bucket = aws_s3_bucket.staging_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for staging
resource "aws_s3_bucket_server_side_encryption_configuration" "staging_website" {
  bucket = aws_s3_bucket.staging_website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block for staging
resource "aws_s3_bucket_public_access_block" "staging_website" {
  bucket = aws_s3_bucket.staging_website.id

  block_public_acls       = false
  block_public_policy       = false
  ignore_public_acls        = false
  restrict_public_buckets    = false
}

# S3 bucket website configuration for staging
resource "aws_s3_bucket_website_configuration" "staging_website" {
  bucket = aws_s3_bucket.staging_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# S3 bucket policy for staging
resource "aws_s3_bucket_policy" "staging_website" {
  bucket = aws_s3_bucket.staging_website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.staging_website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.staging_website]
}

# S3 Bucket for staging access logs
resource "aws_s3_bucket" "staging_access_logs" {
  bucket = "robert-consulting-staging-access-logs"
  
  tags = {
    Name        = "Staging Access Logs"
    Environment = "Staging"
    Purpose     = "CloudFront Access Logs"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning for staging logs
resource "aws_s3_bucket_versioning" "staging_access_logs" {
  bucket = aws_s3_bucket.staging_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for staging logs
resource "aws_s3_bucket_server_side_encryption_configuration" "staging_access_logs" {
  bucket = aws_s3_bucket.staging_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Distribution for staging
resource "aws_cloudfront_distribution" "staging_website" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.staging_website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.staging_website.bucket}"

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
    target_origin_id       = "S3-${aws_s3_bucket.staging_website.bucket}"
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

    # Security headers
    response_headers_policy_id = var.response_headers_policy_id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.staging_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Access logging
  logging_config {
    bucket          = aws_s3_bucket.staging_access_logs.bucket_domain_name
    prefix          = "staging-access-logs/"
    include_cookies = false
  }

  tags = {
    Name        = "Staging Website CDN"
    Environment = "Staging"
    Purpose     = "Staging Content Delivery"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# SNS Topic for staging alerts
resource "aws_sns_topic" "staging_alerts" {
  name = "robert-consulting-staging-alerts"
  
  tags = {
    Name        = "Staging Alerts"
    Environment = "Staging"
    Purpose     = "Staging Notifications"
    ManagedBy   = "Terraform"
  }
}

# Contact Form Lambda Function
resource "aws_lambda_function" "contact_form" {
  filename      = "contact-form.zip"
  function_name = "contact-form-api"
  role          = aws_iam_role.contact_form_lambda_role.arn
  handler       = "contact-form.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 128

  environment {
    variables = {
      SES_REGION = "us-east-1"
    }
  }

  tags = {
    Name        = "Contact Form API"
    Environment = "Production"
    Purpose     = "Contact Form Processing"
    ManagedBy   = "Terraform"
  }
}

# IAM role for contact form Lambda
resource "aws_iam_role" "contact_form_lambda_role" {
  name = "contact-form-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Contact Form Lambda Role"
    Environment = "Production"
    Purpose     = "Contact Form Processing"
    ManagedBy   = "Terraform"
  }
}

# IAM policy for contact form Lambda
resource "aws_iam_role_policy" "contact_form_lambda_policy" {
  name = "contact-form-lambda-policy"
  role = aws_iam_role.contact_form_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source for contact form package
data "archive_file" "contact_form_zip" {
  type        = "zip"
  source_file = "../../lambda/contact-form.js"
  output_path = "contact-form.zip"
}

# Additional Variables
variable "staging_domain_name" {
  description = "Staging domain name"
  type        = string
  default     = "staging.robertconsulting.net"
}

variable "staging_acm_certificate_arn" {
  description = "ACM certificate ARN for staging HTTPS"
  type        = string
}

# Outputs
output "website_bucket_name" {
  description = "Name of the website S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "website_bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.arn
}

output "staging_website_bucket_name" {
  description = "Name of the staging website S3 bucket"
  value       = aws_s3_bucket.staging_website.bucket
}

output "staging_cloudfront_distribution_id" {
  description = "ID of the staging CloudFront distribution"
  value       = aws_cloudfront_distribution.staging_website.id
}

output "contact_form_function_name" {
  description = "Name of the contact form Lambda function"
  value       = aws_lambda_function.contact_form.function_name
}

output "staging_alerts_topic_arn" {
  description = "ARN of the staging alerts SNS topic"
  value       = aws_sns_topic.staging_alerts.arn
}
