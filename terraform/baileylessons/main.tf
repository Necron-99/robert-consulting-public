# Bailey Lessons Infrastructure
# This configuration manages the baileylessons.com infrastructure in account 737915157697

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure AWS provider for baileylessons account
provider "aws" {
  region = "us-east-1"
  
  # Use role assumption for baileylessons account
  assume_role {
    role_arn = "arn:aws:iam::737915157697:role/OrganizationAccountAccessRole"
  }
}

# Data sources for existing resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 Buckets
resource "aws_s3_bucket" "production_static" {
  bucket = "baileylessons-production-static"
  
  tags = {
    Name        = "Bailey Lessons Production Static"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "production_backups" {
  bucket = "baileylessons-production-backups"
  
  tags = {
    Name        = "Bailey Lessons Production Backups"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "production_uploads" {
  bucket = "baileylessons-production-uploads"
  
  tags = {
    Name        = "Bailey Lessons Production Uploads"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "production_logs" {
  bucket = "baileylessons-production-logs"
  
  tags = {
    Name        = "Bailey Lessons Production Logs"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket" "website" {
  bucket = "baileylessons-website-586389c4"
  
  tags = {
    Name        = "Bailey Lessons Website"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket Configurations
resource "aws_s3_bucket_versioning" "production_static" {
  bucket = aws_s3_bucket.production_static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "production_static" {
  bucket = aws_s3_bucket.production_static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "production_static" {
  bucket = aws_s3_bucket.production_static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_s3_bucket.production_static.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.production_static.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Bailey Lessons CloudFront Distribution"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.production_static.id}"
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

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Bailey Lessons CloudFront"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Bailey Lessons OAI"
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "baileylessons.com"

  tags = {
    Name        = "Bailey Lessons Domain"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

# Lambda Functions (will be imported from existing)
resource "aws_lambda_function" "production_api" {
  function_name = "baileylessons-production-api"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "dummy.zip"  # Placeholder for import

  tags = {
    Name        = "Bailey Lessons Production API"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "production_admin" {
  function_name = "baileylessons-production-admin"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "dummy.zip"  # Placeholder for import

  tags = {
    Name        = "Bailey Lessons Production Admin"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "production_auth" {
  function_name = "baileylessons-production-auth"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "dummy.zip"  # Placeholder for import

  tags = {
    Name        = "Bailey Lessons Production Auth"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "baileylessons-lambda-role"

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
    Name        = "Bailey Lessons Lambda Role"
    Environment = "production"
    Project     = "Bailey Lessons"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "account_id" {
  description = "Bailey Lessons AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.production_static.bucket
}
