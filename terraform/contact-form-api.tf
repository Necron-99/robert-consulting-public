# Contact Form API - Lambda Function and API Gateway
# This creates a serverless API for processing contact form submissions

# Lambda function for contact form processing
resource "aws_lambda_function" "contact_form" {
  filename         = "contact-form.zip"
  function_name    = "contact-form-api"
  role            = aws_iam_role.contact_form_lambda_role.arn
  handler         = "contact-form.handler"
  runtime         = "nodejs20.x"
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
  api_key_required = true
  
  # Add request validation
  request_parameters = {
    "method.request.header.Content-Type" = true
    "method.request.header.X-API-Key"     = true
  }
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
# API Gateway Usage Plan for rate limiting
resource "aws_api_gateway_usage_plan" "contact_form_usage_plan" {
  name = "contact-form-usage-plan"
  
  api_stages {
    api_id = aws_api_gateway_rest_api.contact_form_api.id
    stage  = aws_api_gateway_stage.contact_form_stage.stage_name
  }
  
  quota_settings {
    limit  = 1000  # 1000 requests per day
    period = "DAY"
  }
  
  throttle_settings {
    rate_limit  = 10  # 10 requests per second
    burst_limit = 20  # Allow burst up to 20 requests
  }
}

# API Gateway API Key for authentication
resource "aws_api_gateway_api_key" "contact_form_api_key" {
  name = "contact-form-api-key"
  description = "API key for contact form endpoint"
}

# Link API key to usage plan
resource "aws_api_gateway_usage_plan_key" "contact_form_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.contact_form_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.contact_form_usage_plan.id
}

# WAF Web ACL for additional protection
resource "aws_wafv2_web_acl" "contact_form_waf" {
  name  = "contact-form-waf"
  scope = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
  
  # SQL injection protection
  rule {
    name     = "SQLInjectionRule"
    priority = 2
    
    action {
      block {}
    }
    
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }
  }
  
  # XSS protection
  rule {
    name     = "XSSRule"
    priority = 3
    
    action {
      block {}
    }
    
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRule"
      sampled_requests_enabled   = true
    }
  }
  
  tags = {
    Name = "contact-form-waf"
  }
}

# Associate WAF with API Gateway
resource "aws_wafv2_web_acl_association" "contact_form_waf_association" {
  resource_arn = aws_api_gateway_stage.contact_form_stage.arn
  web_acl_arn  = aws_wafv2_web_acl.contact_form_waf.arn
}

output "contact_form_api_url" {
  description = "URL of the contact form API"
  value       = "${aws_api_gateway_deployment.contact_form_deployment.invoke_url}/contact"
}

output "contact_form_api_key" {
  description = "API key for the contact form API"
  value       = aws_api_gateway_api_key.contact_form_api_key.value
  sensitive   = true
}

output "contact_form_lambda_arn" {
  description = "ARN of the contact form Lambda function"
  value       = aws_lambda_function.contact_form.arn
}
