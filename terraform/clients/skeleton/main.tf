# Skeleton Client Infrastructure Template
# This is a template for new client accounts

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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
  backend "s3" {
    bucket         = "robert-consulting-terraform-state"
    key            = "clients/skeleton/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Client      = "Skeleton Client"
      Environment = var.environment
      Purpose     = "Template Infrastructure"
      ManagedBy   = "Robert Consulting"
    }
  }
  # Use OrganizationAccountAccessRole for initial setup
  assume_role {
    role_arn = "arn:aws:iam::${var.client_account_id}:role/OrganizationAccountAccessRole"
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "client_account_id" {
  type        = string
  description = "AWS Account ID for the client"
}

variable "client_name" {
  type        = string
  description = "Name of the client"
  default     = "skeleton"
}

variable "client_domain" {
  type        = string
  description = "Primary domain for the client"
  default     = "example.com"
}

variable "additional_domains" {
  type        = list(string)
  description = "Additional domains for the client"
  default     = []
}

# Call the client infrastructure module
module "infra" {
  source = "../../modules/client-infrastructure"

  client_name        = var.client_name
  client_domain      = var.client_domain
  aws_region         = var.aws_region
  environment        = var.environment
  additional_domains = var.additional_domains
  enable_cloudfront  = true
  enable_waf         = true
  enable_monitoring  = true
}

# Outputs
output "route53_name_servers" {
  value = module.infra.route53_name_servers
}

output "remote_management_role_arn" {
  description = "ARN of the RobertRemoteManagementRole for remote management"
  value       = module.infra.remote_management_role_arn
}

output "remote_management_role_name" {
  description = "Name of the RobertRemoteManagementRole"
  value       = module.infra.remote_management_role_name
}
