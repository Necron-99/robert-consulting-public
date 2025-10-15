# Comprehensive Monitoring for Main Website
# Provides security, performance, and cost monitoring with CloudWatch alarms

variable "monitoring_enabled" {
  description = "Enable comprehensive monitoring for main site"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for receiving monitoring alerts"
  type        = string
  default     = "info@robertconsulting.net"
}

locals {
  monitoring_tags = {
    Project   = "MainSite"
    ManagedBy = "RobertConsulting"
    Purpose   = "Monitoring"
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "main_site_alerts" {
  count = var.monitoring_enabled ? 1 : 0

  name = "main-site-security-alerts"

  tags = local.monitoring_tags
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "main_site_email_alerts" {
  count = var.monitoring_enabled ? 1 : 0

  topic_arn = aws_sns_topic.main_site_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "main_site_waf_logs" {
  count = var.monitoring_enabled ? 1 : 0

  name              = "/aws/wafv2/main-site"
  retention_in_days = 30

  tags = local.monitoring_tags
}

# =============================================================================
# PHASE 1: CRITICAL SECURITY ALERTS
# =============================================================================

# WAF Blocked Requests Alert
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-waf-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors blocked requests by WAF"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    WebACL = "rc-main-site-waf-398fb6"
    Region = "CloudFront"
  }

  tags = local.monitoring_tags
}

# CloudFront 4xx Error Rate Alert
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5.0"
  alarm_description   = "This metric monitors 4xx error rate"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    DistributionId = "E36DBYPHUUKB3V"
  }

  tags = local.monitoring_tags
}

# CloudFront 5xx Error Rate Alert
resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx_errors" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-cloudfront-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1.0"
  alarm_description   = "This metric monitors 5xx error rate"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    DistributionId = "E36DBYPHUUKB3V"
  }

  tags = local.monitoring_tags
}

# =============================================================================
# PHASE 2: PERFORMANCE & AVAILABILITY MONITORING
# =============================================================================

# CloudFront Cache Hit Ratio Alert
resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_ratio" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-cloudfront-cache-hit-ratio"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "80.0"
  alarm_description   = "This metric monitors cache hit ratio"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    DistributionId = "E36DBYPHUUKB3V"
  }

  tags = local.monitoring_tags
}

# CloudFront Origin Response Time Alert
resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_response_time" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-cloudfront-origin-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors origin response time"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    DistributionId = "E36DBYPHUUKB3V"
  }

  tags = local.monitoring_tags
}

# =============================================================================
# PHASE 3: COST OPTIMIZATION MONITORING
# =============================================================================

# CloudFront Data Transfer Cost Alert
resource "aws_cloudwatch_metric_alarm" "cloudfront_data_transfer" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-cloudfront-data-transfer"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BytesDownloaded"
  namespace           = "AWS/CloudFront"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "10737418240" # 10GB
  alarm_description   = "This metric monitors daily data transfer"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    DistributionId = "E36DBYPHUUKB3V"
  }

  tags = local.monitoring_tags
}

# WAF Request Volume Alert
resource "aws_cloudwatch_metric_alarm" "waf_request_volume" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-waf-request-volume"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AllowedRequests"
  namespace           = "AWS/WAFV2"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1000000" # 1M requests
  alarm_description   = "This metric monitors daily WAF request volume"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    WebACL = "rc-main-site-waf-398fb6"
    Region = "CloudFront"
  }

  tags = local.monitoring_tags
}

# =============================================================================
# ADDITIONAL SECURITY MONITORING
# =============================================================================

# Rate Limit Rule Triggered Alert
resource "aws_cloudwatch_metric_alarm" "waf_rate_limit_triggered" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-waf-rate-limit-triggered"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors rate limit rule triggers"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    WebACL = "rc-main-site-waf-398fb6"
    Region = "CloudFront"
    Rule   = "RateLimit"
  }

  tags = local.monitoring_tags
}

# Suspicious User Agent Blocked Alert
resource "aws_cloudwatch_metric_alarm" "waf_suspicious_ua_blocked" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "main-site-waf-suspicious-ua-blocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors suspicious user agent blocks"
  alarm_actions       = [aws_sns_topic.main_site_alerts[0].arn]

  dimensions = {
    WebACL = "rc-main-site-waf-398fb6"
    Region = "CloudFront"
    Rule   = "BlockSuspiciousUserAgents"
  }

  tags = local.monitoring_tags
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "monitoring_sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = var.monitoring_enabled ? aws_sns_topic.main_site_alerts[0].arn : null
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.monitoring_enabled
}

output "alert_email" {
  description = "Email address for alerts"
  value       = var.alert_email
}
