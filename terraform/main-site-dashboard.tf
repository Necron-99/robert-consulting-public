# CloudWatch Dashboard for Main Site Monitoring
# Provides a comprehensive view of security, performance, and cost metrics

resource "aws_cloudwatch_dashboard" "main_site_monitoring" {
  count = var.monitoring_enabled ? 1 : 0

  dashboard_name = "MainSite-Monitoring"

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
            ["AWS/CloudFront", "Requests", "DistributionId", "E36DBYPHUUKB3V", "Region", "Global"],
            [".", "4xxErrorRate", ".", ".", ".", "."],
            [".", "5xxErrorRate", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Requests and Error Rates"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
          annotations = {
            horizontal = [
              {
                label = "No Data Available - CloudFront metrics may take up to 24 hours to appear"
                value = 0
              }
            ]
          }
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
            ["AWS/CloudFront", "TotalErrorRate", "DistributionId", "E36DBYPHUUKB3V", "Region", "Global"],
            [".", "BytesUploaded", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Performance Metrics"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
          annotations = {
            horizontal = [
              {
                label = "No Data Available - Performance metrics may take time to appear"
                value = 0
              }
            ]
          }
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
            ["AWS/WAFV2", "BlockedRequests", "WebACL", "rc-main-site-waf-398fb6", "Region", "CloudFront"],
            [".", "AllowedRequests", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "WAF Security Metrics"
          period  = 300
          yAxis = {
            left = {
              min = 0
            }
          }
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
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", "E36DBYPHUUKB3V", "Region", "Global"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Data Transfer (Cost Monitoring)"
          period  = 3600
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          title = "Active Alarms"
          alarms = [
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-waf-blocked-requests",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-cloudfront-4xx-errors",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-cloudfront-5xx-errors",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-cloudfront-cache-hit-ratio",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-cloudfront-origin-response-time",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-cloudfront-data-transfer",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-waf-request-volume",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-waf-rate-limit-triggered",
            "arn:aws:cloudwatch:us-east-1:228480945348:alarm:main-site-waf-suspicious-ua-blocked"
          ]
        }
      }
    ]
  })
}
