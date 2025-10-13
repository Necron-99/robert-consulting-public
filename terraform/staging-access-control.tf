# Staging Access Control - CloudFront Signed URLs
# This provides secure access to staging without IP whitelisting issues

# CloudFront Key Pair for Signed URLs
resource "aws_cloudfront_public_key" "staging_access_key" {
  comment     = "Staging environment access key"
  encoded_key = file("${path.module}/staging-access-key.pem")
  name        = "staging-access-key"
}

# CloudFront Key Group
resource "aws_cloudfront_key_group" "staging_access_group" {
  comment = "Staging environment access group"
  items   = [aws_cloudfront_public_key.staging_access_key.id]
  name    = "staging-access-group"
}

# Update staging CloudFront distribution to use signed URLs
resource "aws_cloudfront_distribution" "staging_distribution" {
  # ... existing configuration ...
  
  # Add trusted signers for signed URLs
  trusted_signers = [aws_cloudfront_key_group.staging_access_group.id]
  
  # Restrict access to staging
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # Add custom error pages for access denied
  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = "/staging-access-denied.html"
  }
}

# Lambda function to generate signed URLs for testing
resource "aws_lambda_function" "staging_url_generator" {
  filename         = "staging-url-generator.zip"
  function_name    = "staging-url-generator"
  role            = aws_iam_role.lambda_staging_url_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = aws_cloudfront_distribution.staging_distribution.id
      CLOUDFRONT_KEY_PAIR_ID     = aws_cloudfront_public_key.staging_access_key.id
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_staging_url_role" {
  name = "lambda-staging-url-role"

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
resource "aws_iam_role_policy" "lambda_staging_url_policy" {
  name = "lambda-staging-url-policy"
  role = aws_iam_role.lambda_staging_url_role.id

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
          "cloudfront:GetDistribution",
          "cloudfront:GetPublicKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway for staging URL generation
resource "aws_api_gateway_rest_api" "staging_access_api" {
  name        = "staging-access-api"
  description = "API for generating staging access URLs"
}

resource "aws_api_gateway_resource" "staging_url_resource" {
  rest_api_id = aws_api_gateway_rest_api.staging_access_api.id
  parent_id   = aws_api_gateway_rest_api.staging_access_api.root_resource_id
  path_part   = "staging-url"
}

resource "aws_api_gateway_method" "staging_url_method" {
  rest_api_id   = aws_api_gateway_rest_api.staging_access_api.id
  resource_id   = aws_api_gateway_resource.staging_url_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "staging_url_integration" {
  rest_api_id = aws_api_gateway_rest_api.staging_access_api.id
  resource_id = aws_api_gateway_resource.staging_url_resource.id
  http_method = aws_api_gateway_method.staging_url_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.staging_url_generator.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.staging_url_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.staging_access_api.execution_arn}/*/*"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "staging_access_deployment" {
  depends_on = [
    aws_api_gateway_integration.staging_url_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.staging_access_api.id
  stage_name  = "prod"
}

# Output the API Gateway URL
output "staging_access_api_url" {
  description = "URL for staging access API"
  value       = "${aws_api_gateway_deployment.staging_access_deployment.invoke_url}/staging-url"
}
