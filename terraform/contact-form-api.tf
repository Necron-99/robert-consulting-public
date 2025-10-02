# Contact Form API - Lambda Function and API Gateway
# This creates a serverless API for processing contact form submissions

# Lambda function for contact form processing
resource "aws_lambda_function" "contact_form" {
  filename         = "contact-form.zip"
  function_name    = "contact-form-api"
  role            = aws_iam_role.contact_form_lambda_role.arn
  handler         = "contact-form.handler"
  runtime         = "nodejs18.x"
  timeout         = 30
  memory_size     = 128

  environment {
    variables = {
      SES_REGION = "us-east-1"
    }
  }

  tags = {
    Name        = "Contact Form API"
    Environment = "Production"
    Purpose     = "Contact Form Processing"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "contact_form_lambda_role" {
  name = "contact-form-lambda-role"

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
resource "aws_iam_role_policy" "contact_form_lambda_policy" {
  name = "contact-form-lambda-policy"
  role = aws_iam_role.contact_form_lambda_role.id

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
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "contact_form_api" {
  name        = "contact-form-api"
  description = "API for processing contact form submissions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "Contact Form API Gateway"
    Environment = "Production"
    Purpose     = "Contact Form Processing"
  }
}

# API Gateway resource for contact form
resource "aws_api_gateway_resource" "contact_form" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  parent_id   = aws_api_gateway_rest_api.contact_form_api.root_resource_id
  path_part   = "contact"
}

# API Gateway method for POST requests
resource "aws_api_gateway_method" "contact_form_post" {
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.contact_form.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway method for OPTIONS requests (CORS)
resource "aws_api_gateway_method" "contact_form_options" {
  rest_api_id   = aws_api_gateway_rest_api.contact_form_api.id
  resource_id   = aws_api_gateway_resource.contact_form.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Lambda integration for POST method
resource "aws_api_gateway_integration" "contact_form_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form.id
  http_method = aws_api_gateway_method.contact_form_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.contact_form.invoke_arn
}

# CORS integration for OPTIONS method
resource "aws_api_gateway_integration" "contact_form_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form.id
  http_method = aws_api_gateway_method.contact_form_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

# CORS method response for OPTIONS
resource "aws_api_gateway_method_response" "contact_form_options_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form.id
  http_method = aws_api_gateway_method.contact_form_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# CORS integration response for OPTIONS
resource "aws_api_gateway_integration_response" "contact_form_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  resource_id = aws_api_gateway_resource.contact_form.id
  http_method = aws_api_gateway_method.contact_form_options.http_method
  status_code = aws_api_gateway_method_response.contact_form_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "contact_form_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.contact_form_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "contact_form_deployment" {
  depends_on = [
    aws_api_gateway_integration.contact_form_post_integration,
    aws_api_gateway_integration.contact_form_options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.contact_form_api.id
  stage_name  = "prod"

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs
output "contact_form_api_url" {
  description = "URL of the contact form API"
  value       = "${aws_api_gateway_deployment.contact_form_deployment.invoke_url}/contact"
}

output "contact_form_lambda_arn" {
  description = "ARN of the contact form Lambda function"
  value       = aws_lambda_function.contact_form.arn
}
