# AWS CloudWatch Dashboards for Cost and Service Monitoring
# Fixed configuration without problematic dot notation
# Variables are defined in variables.tf

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "robert-consulting-alerts"

  tags = {
    Name        = "Robert Consulting Alerts"
    Environment = "production"
    Purpose     = "monitoring-alerts"
  }
}

# SNS Topic Subscription for Email Notifications
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Cost Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "robert-consulting-cost-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Total AWS Costs"
          period  = 86400
          stat    = "Maximum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.main_site_bucket_name, "StorageType", "StandardStorage"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "S3 Storage Usage"
          period  = 86400
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Requests"
          period  = 3600
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Data Transfer"
          period  = 3600
          stat    = "Sum"
        }
      }
    ]
  })
}

# Service Status Dashboard
resource "aws_cloudwatch_dashboard" "service_status" {
  dashboard_name = "robert-consulting-service-status"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "4xxErrors", "BucketName", var.main_site_bucket_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "S3 4xx Errors"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "5xxErrors", "BucketName", var.main_site_bucket_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "S3 5xx Errors"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront 4xx Error Rate"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "5xxErrorRate", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront 5xx Error Rate"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Cache Hit Rate"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "OriginLatency", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Origin Latency"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}

# Performance Dashboard
resource "aws_cloudwatch_dashboard" "performance_monitoring" {
  dashboard_name = "robert-consulting-performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "OriginLatency", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Origin Latency"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Cache Hit Rate"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Request Volume"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Data Transfer"
          period  = 300
          stat    = "Sum"
        }
      }
    ]
  })
}

# Cost Alerts
resource "aws_cloudwatch_metric_alarm" "high_cost_alert" {
  alarm_name          = "robert-consulting-high-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "15"
  alarm_description   = "This metric monitors AWS costs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_cost_alert" {
  alarm_name          = "robert-consulting-s3-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "5"
  alarm_description   = "This metric monitors S3 costs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
    Service  = "AmazonS3"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cost_alert" {
  alarm_name          = "robert-consulting-cloudfront-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "5"
  alarm_description   = "This metric monitors CloudFront costs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
    Service  = "AmazonCloudFront"
  }
}

# Service Health Alerts
resource "aws_cloudwatch_metric_alarm" "cloudfront_error_rate" {
  alarm_name          = "robert-consulting-cloudfront-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors CloudFront 5xx error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_error_rate" {
  alarm_name          = "robert-consulting-s3-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors S3 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = var.main_site_bucket_name
  }
}

# =============================================================================
# LAMBDA FUNCTION MONITORING
# =============================================================================

# Lambda Error Rate Alarm - Dashboard API
resource "aws_cloudwatch_metric_alarm" "lambda_dashboard_api_errors" {
  alarm_name          = "robert-consulting-lambda-dashboard-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function errors for dashboard-api"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "robert-consulting-dashboard-api"
  }
}

# Lambda Duration Alarm - Dashboard API
resource "aws_cloudwatch_metric_alarm" "lambda_dashboard_api_duration" {
  alarm_name          = "robert-consulting-lambda-dashboard-api-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"  # 10 seconds
  alarm_description   = "This metric monitors Lambda function duration for dashboard-api"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "robert-consulting-dashboard-api"
  }
}

# Lambda Throttles Alarm - Dashboard API
resource "aws_cloudwatch_metric_alarm" "lambda_dashboard_api_throttles" {
  alarm_name          = "robert-consulting-lambda-dashboard-api-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors Lambda function throttles for dashboard-api"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "robert-consulting-dashboard-api"
  }
}

# Lambda Error Rate Alarm - Stats Refresher
resource "aws_cloudwatch_metric_alarm" "lambda_stats_refresher_errors" {
  alarm_name          = "robert-consulting-lambda-stats-refresher-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors Lambda function errors for stats-refresher"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "robert-consulting-stats-refresher"
  }
}

# =============================================================================
# API COST MONITORING (Daily)
# =============================================================================

# Daily API Cost Alarm - Alert if daily API costs exceed $5
# Note: This uses a custom metric that should be published by the rate limiter
resource "aws_cloudwatch_metric_alarm" "daily_api_cost_alert" {
  alarm_name          = "robert-consulting-daily-api-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DailyAPICost"
  namespace           = "CostControl/API"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "5.0"
  alarm_description   = "This metric monitors daily API costs (alerts if > $5/day)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name      = "Daily API Cost Alert"
    Purpose   = "cost-control"
    ManagedBy = "Terraform"
  }
}

# Lambda Invocation Cost Alarm - Alert if Lambda invocations exceed threshold
# This is a proxy for cost since high invocations = higher costs
resource "aws_cloudwatch_metric_alarm" "lambda_high_invocations" {
  alarm_name          = "robert-consulting-lambda-high-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Invocations"
  namespace           = "AWS/Lambda"
  period              = "3600"  # 1 hour
  statistic           = "Sum"
  threshold           = "1000"   # 1000 invocations per hour
  alarm_description   = "This metric monitors Lambda invocations (high invocations = higher costs)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "robert-consulting-dashboard-api"
  }
}

# Outputs
output "cost_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
  description = "URL to the cost monitoring dashboard"
}

output "service_status_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.service_status.dashboard_name}"
  description = "URL to the service status dashboard"
}

output "performance_dashboard_url" {
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.performance_monitoring.dashboard_name}"
  description = "URL to the performance monitoring dashboard"
}
