# CloudWatch Synthetics for Real Performance Monitoring
# This provides network-independent performance testing from AWS edge locations

# IAM role for CloudWatch Synthetics
resource "aws_iam_role" "synthetics_role" {
  name = "robert-consulting-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "CloudWatch Synthetics Role"
    Project = "Robert Consulting"
  }
}

# IAM policy for CloudWatch Synthetics
resource "aws_iam_role_policy" "synthetics_policy" {
  name = "robert-consulting-synthetics-policy"
  role = aws_iam_role.synthetics_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::robert-consulting-synthetics-results/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::robert-consulting-synthetics-results"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::robert-consulting-synthetics-results"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 bucket for Synthetics results
resource "aws_s3_bucket" "synthetics_results" {
  bucket = "robert-consulting-synthetics-results"

  tags = {
    Name    = "CloudWatch Synthetics Results"
    Project = "Robert Consulting"
  }
}

resource "aws_s3_bucket_versioning" "synthetics_results" {
  bucket = aws_s3_bucket.synthetics_results.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "synthetics_results" {
  bucket = aws_s3_bucket.synthetics_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Synthetics Canary for Performance Monitoring
resource "aws_synthetics_canary" "performance_monitor" {
  name                 = "robert-consulting-performance-monitor"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_results.bucket}/performance-monitor"
  execution_role_arn   = aws_iam_role.synthetics_role.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics-performance-monitor.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    active_tracing = true
    timeout_in_seconds = 60
  }

  # Test multiple locations for comprehensive monitoring
  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }

  tags = {
    Name    = "Performance Monitor Canary"
    Project = "Robert Consulting"
  }
}

# CloudWatch Synthetics Canary for Security Headers
resource "aws_synthetics_canary" "security_headers_monitor" {
  name                 = "robert-consulting-security-headers"
  artifact_s3_location = "s3://${aws_s3_bucket.synthetics_results.bucket}/security-headers"
  execution_role_arn   = aws_iam_role.synthetics_role.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics-security-headers.zip"
  runtime_version      = "syn-nodejs-puppeteer-6.2"

  schedule {
    expression = "rate(10 minutes)"
  }

  run_config {
    active_tracing = true
    timeout_in_seconds = 30
  }

  tags = {
    Name    = "Security Headers Monitor Canary"
    Project = "Robert Consulting"
  }
}

# CloudWatch Alarms for Performance Monitoring
resource "aws_cloudwatch_metric_alarm" "performance_lcp_alarm" {
  alarm_name          = "robert-consulting-lcp-performance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "LargestContentfulPaint"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "1800" # 1.8 seconds in milliseconds
  alarm_description   = "This metric monitors LCP performance from AWS edge locations"
  alarm_actions       = [aws_sns_topic.performance_alerts.arn]

  dimensions = {
    CanaryName = aws_synthetics_canary.performance_monitor.name
  }

  tags = {
    Name    = "LCP Performance Alarm"
    Project = "Robert Consulting"
  }
}

resource "aws_cloudwatch_metric_alarm" "performance_ttfb_alarm" {
  alarm_name          = "robert-consulting-ttfb-performance"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TimeToFirstByte"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "200" # 200ms
  alarm_description   = "This metric monitors TTFB performance from AWS edge locations"
  alarm_actions       = [aws_sns_topic.performance_alerts.arn]

  dimensions = {
    CanaryName = aws_synthetics_canary.performance_monitor.name
  }

  tags = {
    Name    = "TTFB Performance Alarm"
    Project = "Robert Consulting"
  }
}

# SNS Topic for Performance Alerts
resource "aws_sns_topic" "performance_alerts" {
  name = "robert-consulting-performance-alerts"

  tags = {
    Name    = "Performance Alerts"
    Project = "Robert Consulting"
  }
}

resource "aws_sns_topic_subscription" "performance_email" {
  topic_arn = aws_sns_topic.performance_alerts.arn
  protocol  = "email"
  endpoint  = "info@robertconsulting.net"
}

# Outputs
output "synthetics_canary_arn" {
  description = "CloudWatch Synthetics Canary ARN"
  value       = aws_synthetics_canary.performance_monitor.arn
}

output "synthetics_results_bucket" {
  description = "S3 bucket for Synthetics results"
  value       = aws_s3_bucket.synthetics_results.bucket
}
