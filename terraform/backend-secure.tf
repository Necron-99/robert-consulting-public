# Secure Terraform Backend Configuration
# Following best practices for production state management

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  
  # Secure S3 backend with proper isolation
  backend "s3" {
    bucket               = "robert-consulting-terraform-state"
    key                  = "org/production/us-east-1/main-infrastructure.tfstate"
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "robert-consulting-terraform-locks"
    # kms_key_id         = "arn:aws:kms:us-east-1:228480945348:key/..." # Add KMS key if available
    # Use workspace_key_prefix for better workspace isolation
    # workspace_key_prefix = "org/production/us-east-1/main-infrastructure"
  }
}

# Default AWS provider with secure defaults
provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "Robert Consulting"
      ManagedBy   = "Terraform"
      Environment = "Production"
      Owner       = "Infrastructure Team"
    }
  }
}

# AWS provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "Robert Consulting"
      ManagedBy   = "Terraform"
      Environment = "Production"
      Owner       = "Infrastructure Team"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
