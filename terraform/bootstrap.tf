# Bootstrap configuration - create S3 bucket and DynamoDB table first
# This file should be applied BEFORE configuring the S3 backend
# After creating the infrastructure, move this file to bootstrap.tf.backup

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Additional provider for ACM certificates in us-east-1
# CloudFront requires certificates to be in us-east-1 region
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "Production"
      ManagedBy   = "Terraform"
      Project     = "Robert Consulting Website"
    }
  }
}

# Backend resources are now defined in backend-resources.tf
