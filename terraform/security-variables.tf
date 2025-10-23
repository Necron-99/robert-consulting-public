# Security-focused variables with validation

variable "environment" {
  description = "Environment name (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

variable "security_level" {
  description = "Security level for resources (high, medium, low)"
  type        = string
  default     = "high"
  
  validation {
    condition     = contains(["high", "medium", "low"], var.security_level)
    error_message = "Security level must be one of: high, medium, low."
  }
}

variable "compliance_requirements" {
  description = "Compliance requirements (SOC2, HIPAA, PCI-DSS, NIST)"
  type        = list(string)
  default     = ["SOC2"]
  
  validation {
    condition = alltrue([
      for req in var.compliance_requirements : contains(["SOC2", "HIPAA", "PCI-DSS", "NIST"], req)
    ])
    error_message = "Compliance requirements must be from: SOC2, HIPAA, PCI-DSS, NIST."
  }
}

variable "data_classification" {
  description = "Data classification level (public, internal, confidential, restricted)"
  type        = string
  default     = "public"
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

# monitoring_enabled variable is already declared in main-site-monitoring.tf

variable "encryption_enabled" {
  description = "Enable encryption at rest and in transit"
  type        = bool
  default     = true
}

variable "waf_enabled" {
  description = "Enable AWS WAF protection"
  type        = bool
  default     = true
}

variable "rate_limit_requests_per_minute" {
  description = "Rate limit for requests per minute per IP"
  type        = number
  default     = 2000
  
  validation {
    condition     = var.rate_limit_requests_per_minute >= 100 && var.rate_limit_requests_per_minute <= 10000
    error_message = "Rate limit must be between 100 and 10000 requests per minute."
  }
}

# Local values for consistent tagging
locals {
  common_security_tags = {
    Environment         = var.environment
    SecurityLevel       = var.security_level
    Compliance          = join(",", var.compliance_requirements)
    DataClassification  = var.data_classification
    ManagedBy          = "Terraform"
    LastModified       = timestamp()
  }
}
