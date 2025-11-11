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

# Note: plex.robertconsulting.net bucket is managed in orphaned-resources.tf
# (aws_s3_bucket.plex_domain) because it's used by the CloudFront distribution there

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

# Note: CloudFront distribution and OAI removed - using the one in orphaned-resources.tf (E3T1Z34I8CU20F)
# which has the active alias plex.robertconsulting.net and uses OAI E3N1PJIQ3V9W9F

# Lambda function for Plex analysis
resource "aws_lambda_function" "plex_analyzer" {
  function_name = "plex-recommendations-analyzer"
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  role          = aws_iam_role.plex_lambda_role.arn
  filename      = "../../lambda/plex-analyzer.zip"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.plex_data.bucket
    }
  }

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

# IAM Policy for Lambda S3 access
resource "aws_iam_role_policy" "plex_lambda_s3_policy" {
  name = "plex-s3-access"
  role = aws_iam_role.plex_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.plex_data.arn,
          "${aws_s3_bucket.plex_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Outputs
output "plex_data_bucket_name" {
  description = "Name of the Plex data S3 bucket"
  value       = aws_s3_bucket.plex_data.bucket
}

# plex_domain_bucket_name output removed - bucket is managed in orphaned-resources.tf

# CloudFront outputs removed - distribution is managed in orphaned-resources.tf
# Active distribution ID: E3T1Z34I8CU20F (has alias plex.robertconsulting.net)

output "plex_lambda_function_name" {
  description = "Lambda function name for Plex analysis"
  value       = aws_lambda_function.plex_analyzer.function_name
}
