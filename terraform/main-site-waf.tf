# WAF Protection for Main Website
# Provides comprehensive security for the main Robert Consulting website

variable "main_site_waf_enabled" {
  description = "Enable WAF protection for main website"
  type        = bool
  default     = true
}

locals {
  main_waf_tags = {
    Project   = "MainSite"
    ManagedBy = "Robert Consulting"
    Purpose   = "Website Protection"
  }
}

# Random ID for unique naming
resource "random_id" "main_waf_suffix" {
  byte_length = 3
}

# WAF Web ACL for main website protection
resource "aws_wafv2_web_acl" "main_site" {
  count = var.main_site_waf_enabled ? 1 : 0
  
  name  = "rc-main-site-waf-${random_id.main_waf_suffix.hex}"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule - prevent DDoS and abuse
  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # Block requests with suspicious User-Agent patterns
  rule {
    name     = "BlockSuspiciousUserAgents"
    priority = 2

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string         = "sqlmap"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockSuspiciousUserAgents"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainSiteWAF"
    sampled_requests_enabled   = true
  }

  tags = local.main_waf_tags
}

# Outputs
output "main_site_waf_arn" {
  description = "ARN of the main site WAF Web ACL"
  value       = var.main_site_waf_enabled ? aws_wafv2_web_acl.main_site[0].arn : null
}

output "main_site_waf_id" {
  description = "ID of the main site WAF Web ACL"
  value       = var.main_site_waf_enabled ? aws_wafv2_web_acl.main_site[0].id : null
}
