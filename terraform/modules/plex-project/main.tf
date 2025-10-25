# Plex Project Infrastructure Module
# This module manages the Plex recommendations project

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }
}

# Variables
variable "project_name" {
  description = "Plex project name"
  type        = string
  default     = "plex-recommendations"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# S3 Bucket for Plex data
resource "aws_s3_bucket" "plex_data" {
  bucket = "plex-recommendations-c7c49ce4"
  
  tags = {
    Name        = "Plex Recommendations Data"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket for Plex domain
resource "aws_s3_bucket" "plex_domain" {
  bucket = "plex.robertconsulting.net"
  
  tags = {
    Name        = "Plex Domain"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket Configurations
resource "aws_s3_bucket_versioning" "plex_data" {
  bucket = aws_s3_bucket.plex_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "plex_data" {
  bucket = aws_s3_bucket.plex_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "plex_data" {
  bucket = aws_s3_bucket.plex_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution for Plex project
resource "aws_cloudfront_distribution" "plex_distribution" {
  origin {
    domain_name = aws_s3_bucket.plex_domain.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.plex_domain.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.plex_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Plex Recommendations Project"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.plex_domain.id}"
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
    Name        = "Plex Recommendations Distribution"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "plex_oai" {
  comment = "Plex Recommendations OAI"
}

# Lambda function for Plex analysis
resource "aws_lambda_function" "plex_analyzer" {
  function_name = "plex-recommendations-analyzer"
  runtime       = "python3.9"
  handler       = "index.handler"
  role          = aws_iam_role.plex_lambda_role.arn

  tags = {
    Name        = "Plex Recommendations Analyzer"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "plex_lambda_role" {
  name = "plex-recommendations-lambda-role"

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
    Name        = "Plex Recommendations Lambda Role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "plex_data_bucket_name" {
  description = "Name of the Plex data S3 bucket"
  value       = aws_s3_bucket.plex_data.bucket
}

output "plex_domain_bucket_name" {
  description = "Name of the Plex domain S3 bucket"
  value       = aws_s3_bucket.plex_domain.bucket
}

output "plex_cloudfront_distribution_id" {
  description = "CloudFront Distribution ID for Plex project"
  value       = aws_cloudfront_distribution.plex_distribution.id
}

output "plex_cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name for Plex project"
  value       = aws_cloudfront_distribution.plex_distribution.domain_name
}

output "plex_lambda_function_name" {
  description = "Lambda function name for Plex analysis"
  value       = aws_lambda_function.plex_analyzer.function_name
}
