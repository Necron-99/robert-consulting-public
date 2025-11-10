# CloudWatch Dashboard for Resource Catalog
# Provides visualization of resource status and utilization

resource "aws_cloudwatch_dashboard" "resource_catalog" {
  dashboard_name = "robert-consulting-resource-catalog"

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
            ["AWS/Lambda", "Invocations", { "stat": "Sum", "label": "Resource Cataloger Invocations" }]
          ]
          period = 86400
          stat   = "Sum"
          region = "us-east-1"
          title  = "Resource Cataloger Activity"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query = <<-EOT
SOURCE '/aws/lambda/robert-consulting-resource-cataloger' | fields @timestamp, @message
| filter @message like /needs-attention/
| sort @timestamp desc
| limit 20
EOT
          region = "us-east-1"
          title  = "Resources Needing Attention"
        }
      }
    ]
  })
}

# CloudWatch Alarm for untagged resources
resource "aws_cloudwatch_metric_alarm" "untagged_resources" {
  alarm_name          = "robert-consulting-untagged-resources"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UntaggedResources"
  namespace           = "ResourceCatalog"
  period              = 86400 # 1 day
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when more than 5 untagged resources are detected"
  alarm_actions       = [aws_sns_topic.resource_alerts.arn]

  tags = {
    Name        = "Untagged Resources Alarm"
    Purpose     = "resource-tracking"
    ManagedBy   = "Terraform"
    Environment = "production"
    Project     = "Robert Consulting"
  }
}

# CloudWatch Alarm for unused resources
resource "aws_cloudwatch_metric_alarm" "unused_resources" {
  alarm_name          = "robert-consulting-unused-resources"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnusedResources"
  namespace           = "ResourceCatalog"
  period              = 86400 # 1 day
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when more than 10 unused resources are detected"
  alarm_actions       = [aws_sns_topic.resource_alerts.arn]

  tags = {
    Name        = "Unused Resources Alarm"
    Purpose     = "resource-tracking"
    ManagedBy   = "Terraform"
    Environment = "production"
    Project     = "Robert Consulting"
  }
}

