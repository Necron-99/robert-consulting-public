# [CLIENT_NAME] Infrastructure Configuration
# This file manages the client's AWS infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "clients/[CLIENT_NAME]/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Provider configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Client      = var.client_name
      Environment = var.environment
      Purpose     = "Client Infrastructure"
      ManagedBy   = "Robert Consulting"
    }
  }

  # Assume role in client account
  assume_role {
    role_arn = "arn:aws:iam::${var.client_account_id}:role/RobertClientDeploymentRole"
  }
}

# Client infrastructure module
module "infrastructure" {
  source = "./modules/client-infrastructure"

  # Client configuration
  client_name        = var.client_name
  client_domain      = var.client_domain
  aws_region         = var.aws_region
  environment        = var.environment
  additional_domains = var.additional_domains

  # Features
  enable_cloudfront  = var.enable_cloudfront
  enable_waf         = var.enable_waf
  enable_monitoring  = var.enable_monitoring

  # Existing resources (if adopting)
  existing_cloudfront_distribution_id = var.existing_cloudfront_distribution_id
  existing_route53_zone_id            = var.existing_route53_zone_id
  existing_acm_certificate_arn       = var.existing_acm_certificate_arn
}

# Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.infrastructure.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.infrastructure.cloudfront_domain_name
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.infrastructure.route53_zone_id
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = module.infrastructure.route53_name_servers
}

output "s3_bucket_name" {
  description = "S3 bucket name for website hosting"
  value       = module.infrastructure.bucket_name
}
