# Main Terraform configuration for client infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Client      = var.client_name
    }
  }
}

# Configure GitHub Provider
provider "github" {
  token = var.github_token
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values for common configurations
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Client      = var.client_name
    ManagedBy   = "Terraform"
  }
  
  # Cost optimization: Use smaller instance types for non-production
  instance_type = var.environment == "production" ? var.production_instance_type : var.development_instance_type
  
  # Database instance class based on environment
  db_instance_class = var.environment == "production" ? var.production_db_instance_class : var.development_db_instance_class
}
