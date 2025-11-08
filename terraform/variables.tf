# Terraform Variables
# Centralized variable definitions for the Robert Consulting infrastructure

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for the main website"
  type        = string
  default     = "E36DBYPHUUKB3V"
  
  validation {
    condition     = can(regex("^E[A-Z0-9]{13}$", var.cloudfront_distribution_id))
    error_message = "CloudFront distribution ID must be a valid format (e.g., E36DBYPHUUKB3V)"
  }
}

variable "main_site_bucket_name" {
  description = "S3 bucket name for the main website"
  type        = string
  default     = "robert-consulting-website"
}

variable "alert_email" {
  description = "Email address for receiving monitoring alerts"
  type        = string
  default     = "rsbailey@necron99.org"
}

variable "monitoring_enabled" {
  description = "Enable comprehensive monitoring"
  type        = bool
  default     = true
}

