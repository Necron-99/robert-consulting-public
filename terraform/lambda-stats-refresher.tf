# Lambda function for refreshing dashboard statistics
resource "aws_lambda_function" "stats_refresher" {
  filename         = "lambda/stats-refresher.zip"
  function_name    = "dashboard-stats-refresher"
  role             = aws_iam_role.stats_refresher_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.stats_refresher_zip.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      GITHUB_USERNAME            = "Necron-99"
      GITHUB_TOKEN_SECRET_ID     = aws_secretsmanager_secret.github_token.name
      CLOUDFRONT_DISTRIBUTION_ID = "E36DBYPHUUKB3V"
      PROD_BUCKET                = "robert-consulting-website"
      LOG_LEVEL                  = "INFO"
    }
  }

  tags = {
    Name        = "dashboard-stats-refresher"
    Environment = "production"
    Purpose     = "dashboard-stats"
  }
}

# IAM role for the Lambda function
resource "aws_iam_role" "stats_refresher_role" {
  name = "dashboard-stats-refresher-role"

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
    Name        = "dashboard-stats-refresher-role"
    Environment = "production"
  }
}

# IAM policy for the Lambda function
resource "aws_iam_role_policy" "stats_refresher_policy" {
  name = "dashboard-stats-refresher-policy"
  role = aws_iam_role.stats_refresher_role.id

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
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.github_token.arn
      },
      # Cost Explorer permissions removed to eliminate costs
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::robert-consulting-website/data/dashboard-stats.json"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/E36DBYPHUUKB3V"
      }
    ]
  })
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "stats_refresher_logs" {
  name              = "/aws/lambda/dashboard-stats-refresher"
  retention_in_days = 14

  tags = {
    Name        = "dashboard-stats-refresher-logs"
    Environment = "production"
  }
}

# Secrets Manager secret for GitHub token
resource "aws_secretsmanager_secret" "github_token" {
  name        = "github-token-dashboard-stats"
  description = "GitHub personal access token for dashboard statistics"

  tags = {
    Name        = "github-token-dashboard-stats"
    Environment = "production"
    Purpose     = "dashboard-stats"
  }
}

# Secrets Manager secret version (placeholder - you'll need to set the actual token)
resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id = aws_secretsmanager_secret.github_token.id
  secret_string = jsonencode({
    token = "your-github-token-here"
  })
}

# API Gateway for manual refresh endpoint
resource "aws_api_gateway_rest_api" "stats_refresher_api" {
  name        = "dashboard-stats-refresher-api"
  description = "API for manually refreshing dashboard statistics"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "dashboard-stats-refresher-api"
    Environment = "production"
  }
}

resource "aws_api_gateway_resource" "stats_refresher_resource" {
  rest_api_id = aws_api_gateway_rest_api.stats_refresher_api.id
  parent_id   = aws_api_gateway_rest_api.stats_refresher_api.root_resource_id
  path_part   = "refresh-stats"
}

resource "aws_api_gateway_method" "stats_refresher_method" {
  rest_api_id   = aws_api_gateway_rest_api.stats_refresher_api.id
  resource_id   = aws_api_gateway_resource.stats_refresher_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "stats_refresher_integration" {
  rest_api_id = aws_api_gateway_rest_api.stats_refresher_api.id
  resource_id = aws_api_gateway_resource.stats_refresher_resource.id
  http_method = aws_api_gateway_method.stats_refresher_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.stats_refresher.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stats_refresher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stats_refresher_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "stats_refresher_deployment" {
  depends_on = [
    aws_api_gateway_integration.stats_refresher_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.stats_refresher_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "stats_refresher_stage" {
  deployment_id = aws_api_gateway_deployment.stats_refresher_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.stats_refresher_api.id
  stage_name    = "prod"
}

# Data source for current AWS account ID (already defined in state-management.tf)

# Archive file for Lambda deployment package
data "archive_file" "stats_refresher_zip" {
  type        = "zip"
  source_dir  = "lambda/stats-refresher"
  output_path = "lambda/stats-refresher.zip"
  depends_on  = [null_resource.build_lambda_package]
}

# Build the Lambda package
resource "null_resource" "build_lambda_package" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd lambda/stats-refresher
      npm install --production
      cd ../..
    EOT
  }
}

# Outputs
output "stats_refresher_lambda_arn" {
  description = "ARN of the stats refresher Lambda function"
  value       = aws_lambda_function.stats_refresher.arn
}

output "stats_refresher_api_url" {
  description = "URL of the stats refresher API Gateway"
  value       = "${aws_api_gateway_stage.stats_refresher_stage.invoke_url}/refresh-stats"
}

output "github_token_secret_name" {
  description = "Name of the GitHub token secret"
  value       = aws_secretsmanager_secret.github_token.name
  sensitive   = true
}
