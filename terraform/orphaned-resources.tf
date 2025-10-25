# Orphaned Resources Configuration
# These resources exist in AWS but are not managed by Terraform

# Plex Recommendations S3 Buckets
resource "aws_s3_bucket" "plex_recommendations_data" {
  bucket = "plex-recommendations-data-1e15cfbc"
  
  tags = {
    Name        = "Plex Recommendations Data"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "Plex data storage and analysis"
  }
}

resource "aws_s3_bucket" "plex_domain" {
  bucket = "plex.robertconsulting.net"
  
  tags = {
    Name        = "Plex Domain Bucket"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "Plex domain hosting"
  }
}

# Cache and Test Buckets
resource "aws_s3_bucket" "cache" {
  bucket = "robert-consulting-cache"
  
  tags = {
    Name        = "Robert Consulting Cache"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "Caching and temporary storage"
  }
}

resource "aws_s3_bucket" "terraform_test" {
  bucket = "robert-consulting-terraform-test-1761410906"
  
  tags = {
    Name        = "Terraform Test Bucket"
    Environment = "production"
    ManagedBy   = "Terraform"
    Purpose     = "Terraform testing and validation"
  }
}

# Plex CloudFront Distribution
resource "aws_cloudfront_distribution" "plex_distribution" {
  origin {
    domain_name = "plex.robertconsulting.net.s3.amazonaws.com"
    origin_id   = "S3-plex.robertconsulting.net"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.plex_oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Plex Recommendations Distribution"
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-plex.robertconsulting.net"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  price_class = "PriceClass_100"
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name        = "Plex Recommendations Distribution"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Plex CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "plex_oai" {
  comment = "Plex Recommendations OAI"
}

# Plex Lambda Functions
resource "aws_lambda_function" "plex_analyzer" {
  function_name = "plex-analyzer"
  role          = aws_iam_role.plex_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "lambda/plex-analyzer.zip"
  
  tags = {
    Name        = "Plex Analyzer"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "robert_consulting_plex_analyzer" {
  function_name = "robert-consulting-plex-analyzer"
  role          = aws_iam_role.plex_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "lambda/robert-consulting-plex-analyzer.zip"
  
  tags = {
    Name        = "Robert Consulting Plex Analyzer"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_lambda_function" "terraform_stats_refresher" {
  function_name = "robert-consulting-terraform-stats-refresher"
  role          = aws_iam_role.plex_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "lambda/terraform-stats-refresher.zip"
  
  tags = {
    Name        = "Terraform Stats Refresher"
    Project     = "monitoring"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Plex Lambda Functions
resource "aws_iam_role" "plex_lambda_role" {
  name = "plex-lambda-role"
  
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
    Name        = "Plex Lambda Role"
    Project     = "plex-recommendations"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
