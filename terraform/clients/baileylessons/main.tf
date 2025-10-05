# Bailey Lessons Client Infrastructure (standalone stack)

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
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Client      = "Bailey Lessons"
      Environment = var.environment
      Purpose     = "Educational Platform"
      ManagedBy   = "Robert Consulting"
    }
  }
  # Temporarily use OrganizationAccountAccessRole to create remote management role
  assume_role {
    role_arn = "arn:aws:iam::737915157697:role/OrganizationAccountAccessRole"
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

module "infra" {
  source = "../../modules/client-infrastructure"

  client_name        = "baileylessons"
  client_domain      = "baileylessons.com"
  aws_region         = var.aws_region
  environment        = var.environment
  additional_domains = ["www.baileylessons.com", "app.baileylessons.com"]
  enable_cloudfront  = true
  enable_waf         = true
  enable_monitoring  = true
}

# Additional client-specific resources can go here as needed

output "route53_name_servers" {
  value = module.infra.route53_name_servers
}


