# Monitoring Infrastructure Module
# This module manages monitoring and analytics resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
  }
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "github_token_secret_name" {
  description = "Name of the GitHub token secret in Secrets Manager"
  type        = string
  default     = "github-token"
}

# S3 Bucket for synthetics results
resource "aws_s3_bucket" "synthetics_results" {
  bucket = "robert-consulting-synthetics-results"
  
  tags = {
    Name        = "Synthetics Results"
    Environment = var.environment
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning for synthetics
resource "aws_s3_bucket_versioning" "synthetics_results" {
  bucket = aws_s3_bucket.synthetics_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for synthetics
resource "aws_s3_bucket_server_side_encryption_configuration" "synthetics_results" {
  bucket = aws_s3_bucket.synthetics_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lambda function for dashboard API
resource "aws_lambda_function" "dashboard_api" {
  filename         = "dashboard-api.zip"
  function_name    = "robert-consulting-dashboard-api"
  role            = aws_iam_role.dashboard_api_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.dashboard_api_zip.output_base64sha256
  runtime         = "nodejs22.x"
  timeout         = 30

  environment {
    variables = {
      GITHUB_TOKEN_SECRET_NAME = var.github_token_secret_name
    }
  }

  tags = {
    Name        = "Dashboard API"
    Environment = var.environment
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
  }
}

# Lambda function for stats refresher
resource "aws_lambda_function" "stats_refresher" {
  filename         = "stats-refresher.zip"
  function_name    = "robert-consulting-stats-refresher"
  role            = aws_iam_role.stats_refresher_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.stats_refresher_zip.output_base64sha256
  runtime         = "nodejs22.x"
  timeout         = 300

  environment {
    variables = {
      GITHUB_TOKEN_SECRET_NAME = var.github_token_secret_name
    }
  }

  tags = {
    Name        = "Stats Refresher"
    Environment = var.environment
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
  }
}

# IAM role for dashboard API
resource "aws_iam_role" "dashboard_api_role" {
  name = "robert-consulting-dashboard-api-role"

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
    Name        = "Dashboard API Role"
    Environment = var.environment
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
  }
}

# IAM role for stats refresher
resource "aws_iam_role" "stats_refresher_role" {
  name = "robert-consulting-stats-refresher-role"

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
    Name        = "Stats Refresher Role"
    Environment = var.environment
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
  }
}

# IAM policy for dashboard API
resource "aws_iam_role_policy" "dashboard_api_policy" {
  name = "robert-consulting-dashboard-api-policy"
  role = aws_iam_role.dashboard_api_role.id

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
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.github_token_secret_name}*"
      }
    ]
  })
}

# IAM policy for stats refresher
resource "aws_iam_role_policy" "stats_refresher_policy" {
  name = "robert-consulting-stats-refresher-policy"
  role = aws_iam_role.stats_refresher_role.id

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
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.github_token_secret_name}*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.synthetics_results.arn}/*"
      }
    ]
  })
}

# Data sources for Lambda packages
data "archive_file" "dashboard_api_zip" {
  type        = "zip"
  source_dir  = "../../lambda"
  output_path = "dashboard-api.zip"
  excludes    = ["package-lock.json", "node_modules", "*.md"]
}

data "archive_file" "stats_refresher_zip" {
  type        = "zip"
  source_dir  = "../../lambda/stats-refresher"
  output_path = "stats-refresher.zip"
  excludes    = ["package-lock.json", "node_modules", "*.md"]
}

# Outputs
output "synthetics_bucket_name" {
  description = "Name of the synthetics results S3 bucket"
  value       = aws_s3_bucket.synthetics_results.bucket
}

output "dashboard_api_function_name" {
  description = "Name of the dashboard API Lambda function"
  value       = aws_lambda_function.dashboard_api.function_name
}

output "stats_refresher_function_name" {
  description = "Name of the stats refresher Lambda function"
  value       = aws_lambda_function.stats_refresher.function_name
}
