# Dashboard API - Real-time AWS data via API Gateway + Lambda

resource "aws_lambda_function" "dashboard_api" {
  filename         = "dashboard-api.zip"
  function_name    = "robert-consulting-dashboard-api"
  role            = aws_iam_role.dashboard_api_role.arn
  handler         = "dashboard-api.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      NODE_ENV = "production"
    }
  }

  tags = {
    Name        = "Dashboard API"
    Project     = "Robert Consulting"
    Environment = "Production"
  }
}

# IAM role for the Lambda function
resource "aws_iam_role" "dashboard_api_role" {
  name = "robert-consulting-dashboard-api-role"

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
    Name    = "Dashboard API Role"
    Project = "Robert Consulting"
  }
}

# IAM policy for the Lambda function
resource "aws_iam_role_policy" "dashboard_api_policy" {
  name = "robert-consulting-dashboard-api-policy"
  role = aws_iam_role.dashboard_api_role.id

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
          "ce:GetCostAndUsage",
          "ce:GetUsageReport",
          "ce:ListCostCategoryDefinitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:ListObjectsV2"
        ]
        Resource = [
          "arn:aws:s3:::robert-consulting-website",
          "arn:aws:s3:::robert-consulting-website/*",
          "arn:aws:s3:::robert-consulting-staging-website",
          "arn:aws:s3:::robert-consulting-staging-website/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZones"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/Z0232243368137F38UDI1"
        ]
      }
    ]
  })
}

# API Gateway
resource "aws_api_gateway_rest_api" "dashboard_api" {
  name        = "robert-consulting-dashboard-api"
  description = "Dashboard API for real-time AWS data"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name    = "Dashboard API Gateway"
    Project = "Robert Consulting"
  }
}

# API Gateway resource
resource "aws_api_gateway_resource" "dashboard_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.dashboard_api.id
  parent_id   = aws_api_gateway_rest_api.dashboard_api.root_resource_id
  path_part   = "dashboard-data"
}

# API Gateway method
resource "aws_api_gateway_method" "dashboard_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.dashboard_api.id
  resource_id   = aws_api_gateway_resource.dashboard_api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway integration
resource "aws_api_gateway_integration" "dashboard_api_integration" {
  rest_api_id = aws_api_gateway_rest_api.dashboard_api.id
  resource_id = aws_api_gateway_resource.dashboard_api_resource.id
  http_method = aws_api_gateway_method.dashboard_api_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.dashboard_api.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "dashboard_api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dashboard_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.dashboard_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "dashboard_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.dashboard_api_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.dashboard_api.id
  stage_name  = "prod"

  lifecycle {
    create_before_destroy = true
  }
}

# Output the API Gateway URL
output "dashboard_api_url" {
  description = "Dashboard API Gateway URL"
  value       = "${aws_api_gateway_deployment.dashboard_api_deployment.invoke_url}/dashboard-data"
}
