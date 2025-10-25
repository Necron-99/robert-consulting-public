# Shared Infrastructure Module
# This module manages resources shared across all projects

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

# Data sources for AWS account and region information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Route53 Zone (shared across all projects)
resource "aws_route53_zone" "main" {
  name = var.domain_name
  
  tags = {
    Name        = "Main DNS Zone"
    Environment = var.environment
    Project     = "Shared"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket for cache (shared)
resource "aws_s3_bucket" "cache" {
  bucket = "robert-consulting-cache"
  
  tags = {
    Name        = "Shared Cache"
    Environment = var.environment
    Project     = "Shared"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning for cache
resource "aws_s3_bucket_versioning" "cache" {
  bucket = aws_s3_bucket.cache.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for cache
resource "aws_s3_bucket_server_side_encryption_configuration" "cache" {
  bucket = aws_s3_bucket.cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket for Terraform state (shared)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "robert-consulting-terraform-state"
  
  tags = {
    Name        = "Terraform State"
    Environment = var.environment
    Project     = "Shared"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning for Terraform state
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption for Terraform state
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "robert-consulting-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = var.environment
    Project     = "Shared"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "route53_zone_id" {
  description = "ID of the main Route53 zone"
  value       = aws_route53_zone.main.zone_id
}

output "cache_bucket_name" {
  description = "Name of the shared cache S3 bucket"
  value       = aws_s3_bucket.cache.bucket
}

output "terraform_state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_locks_table_name" {
  description = "Name of the Terraform state locks DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}
