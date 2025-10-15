# WAF Protection for Existing Admin Site
# This adds WAF protection to the existing admin site without duplicating resources

variable "admin_allowed_ips" {
  description = "List of IP addresses allowed to access the admin site"
  type        = list(string)
  default     = [] # Add your IP addresses here
}

variable "admin_waf_enabled" {
  description = "Enable WAF protection for admin site"
  type        = bool
  default     = false
}

locals {
  waf_tags = {
    Project   = "AdminSite"
    ManagedBy = "Robert Consulting"
    Purpose   = "WAF Protection"
  }
}

# Random ID for unique naming
resource "random_id" "waf_suffix" {
  byte_length = 3
}

# WAF Web ACL for admin site protection
resource "aws_wafv2_web_acl" "admin_protection" {
  count = var.admin_waf_enabled ? 1 : 0

  name  = "rc-admin-waf-${random_id.waf_suffix.hex}"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  # IP Set for allowed IPs (if any are specified)
  dynamic "rule" {
    for_each = length(var.admin_allowed_ips) > 0 ? [1] : []
    content {
      name     = "AllowAdminIPs"
      priority = 1

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.admin_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowAdminIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimit"
    priority = 2

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

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AdminWAF"
    sampled_requests_enabled   = true
  }

  tags = local.waf_tags
}

# IP Set for allowed IPs
resource "aws_wafv2_ip_set" "admin_ips" {
  count = var.admin_waf_enabled && length(var.admin_allowed_ips) > 0 ? 1 : 0

  name  = "rc-admin-allowed-ips-${random_id.waf_suffix.hex}"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = [for ip in var.admin_allowed_ips : "${ip}/32"]

  tags = local.waf_tags
}

# Outputs
output "waf_web_acl_arn" {
  value       = var.admin_waf_enabled ? aws_wafv2_web_acl.admin_protection[0].arn : null
  description = "WAF Web ACL ARN for admin site"
}

output "waf_web_acl_id" {
  value       = var.admin_waf_enabled ? aws_wafv2_web_acl.admin_protection[0].id : null
  description = "WAF Web ACL ID for admin site"
}

output "waf_enabled" {
  value       = var.admin_waf_enabled
  description = "Whether WAF protection is enabled"
}
