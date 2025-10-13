# Staging Access Control - Simple Query Parameter Authentication
# This provides secure access to staging without IP whitelisting issues

# Lambda function to generate access URLs for staging
resource "aws_lambda_function" "staging_token_generator" {
  filename         = "staging-token-generator.zip"
  function_name    = "staging-token-generator"
  role            = aws_iam_role.lambda_staging_token_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      STAGING_ACCESS_TOKEN = var.staging_access_token
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_staging_token_role" {
  name = "lambda-staging-token-role"

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
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda_staging_token_policy" {
  name = "lambda-staging-token-policy"
  role = aws_iam_role.lambda_staging_token_role.id

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
      }
    ]
  })
}

# API Gateway for staging token generation
resource "aws_api_gateway_rest_api" "staging_token_api" {
  name        = "staging-token-api"
  description = "API for generating staging access tokens"
}

resource "aws_api_gateway_resource" "staging_token_resource" {
  rest_api_id = aws_api_gateway_rest_api.staging_token_api.id
  parent_id   = aws_api_gateway_rest_api.staging_token_api.root_resource_id
  path_part   = "staging-token"
}

resource "aws_api_gateway_method" "staging_token_method" {
  rest_api_id   = aws_api_gateway_rest_api.staging_token_api.id
  resource_id   = aws_api_gateway_resource.staging_token_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "staging_token_integration" {
  rest_api_id = aws_api_gateway_rest_api.staging_token_api.id
  resource_id = aws_api_gateway_resource.staging_token_resource.id
  http_method = aws_api_gateway_method.staging_token_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.staging_token_generator.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda_token" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.staging_token_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.staging_token_api.execution_arn}/*/*"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "staging_token_deployment" {
  depends_on = [
    aws_api_gateway_integration.staging_token_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.staging_token_api.id
  stage_name  = "prod"
}

# Variable for staging access token
variable "staging_access_token" {
  description = "Secret token for staging access"
  type        = string
  default     = "staging-access-2025"
  sensitive   = true
}

# Output the API Gateway URL
output "staging_token_api_url" {
  description = "URL for staging token API"
  value       = "${aws_api_gateway_deployment.staging_token_deployment.invoke_url}/staging-token"
}

