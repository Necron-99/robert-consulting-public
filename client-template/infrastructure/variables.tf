# [CLIENT_NAME] Infrastructure Variables

# Client Information
variable "client_name" {
  description = "Name of the client"
  type        = string
}

variable "client_domain" {
  description = "Primary domain for the client"
  type        = string
}

variable "client_account_id" {
  description = "AWS account ID for the client"
  type        = string
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

# Domain Configuration
variable "additional_domains" {
  description = "Additional domains to support"
  type        = list(string)
  default     = []
}

# Feature Flags
variable "enable_cloudfront" {
  description = "Enable CloudFront CDN"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

# Existing Resources (for adoption)
variable "existing_cloudfront_distribution_id" {
  description = "Existing CloudFront distribution ID to adopt"
  type        = string
  default     = null
}

variable "existing_route53_zone_id" {
  description = "Existing Route53 hosted zone ID to adopt"
  type        = string
  default     = null
}

variable "existing_acm_certificate_arn" {
  description = "Existing ACM certificate ARN (us-east-1) to use"
  type        = string
  default     = null
}
