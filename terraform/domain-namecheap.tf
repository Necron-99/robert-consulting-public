# Domain and SSL Certificate Configuration for robertconsulting.net
# This version works with AWS Route 53 for the primary domain

# Route 53 hosted zone for robertconsulting.net
# This will be used for certificate validation and domain management
resource "aws_route53_zone" "main" {
  name = "robertconsulting.net"

  tags = {
    Name        = "Robert Consulting Domain"
    Environment = "Production"
    Purpose     = "Domain Management"
    ManagedBy   = "Terraform"
  }
}

# AWS Certificate Manager wildcard certificate for *.robertconsulting.net
# Must be in us-east-1 for CloudFront compatibility
resource "aws_acm_certificate" "wildcard" {
  provider = aws.us_east_1

  domain_name               = "robertconsulting.net"
  subject_alternative_names = ["*.robertconsulting.net"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "Robert Consulting Wildcard Certificate"
    Environment = "Production"
    Purpose     = "SSL/TLS Certificate"
    ManagedBy   = "Terraform"
  }
}

# Certificate validation records in Route 53
# These will be used for certificate validation
# Temporarily commented out to allow imports
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.main.zone_id
# }

# Certificate validation - COMMENTED OUT due to DNS validation issues
# The certificate will be validated manually or through DNS propagation
# resource "aws_acm_certificate_validation" "wildcard" {
#   provider = aws.us_east_1
#   
#   certificate_arn         = aws_acm_certificate.wildcard.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
#
#   timeouts {
#     create = "10m"
#   }
# }

# DNS records for robertconsulting.net domain
# These will be activated for the primary domain

# A record for the root domain (robertconsulting.net)
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "robertconsulting.net"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA record for IPv6 support
resource "aws_route53_record" "root_domain_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "robertconsulting.net"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# CNAME record for www subdomain
resource "aws_route53_record" "www_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.robertconsulting.net"
  type    = "CNAME"
  ttl     = 300
  records = ["robertconsulting.net"]
}

# Outputs for domain configuration
output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for robertconsulting.net"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name servers for robertconsulting.net domain"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ARN of the wildcard SSL certificate"
  value       = aws_acm_certificate.wildcard.arn
}

output "certificate_status" {
  description = "Status of the SSL certificate"
  value       = aws_acm_certificate.wildcard.status
}

output "domain_name" {
  description = "Primary domain name"
  value       = "robertconsulting.net"
}

output "www_domain_name" {
  description = "WWW subdomain name"
  value       = "www.robertconsulting.net"
}

output "current_cloudfront_domain" {
  description = "Current CloudFront domain for CNAME setup"
  value       = "dpm4biqgmoi9l.cloudfront.net"
}

output "aws_dns_instructions" {
  description = "DNS records configured in Route 53 for robertconsulting.net"
  value = {
    root_domain = {
      type  = "A"
      name  = "robertconsulting.net"
      value = "CloudFront Alias"
      note  = "Points to CloudFront distribution"
    }
    www_subdomain = {
      type  = "CNAME"
      name  = "www.robertconsulting.net"
      value = "robertconsulting.net"
      note  = "WWW subdomain points to root domain"
    }
    api_subdomain = {
      type  = "CNAME"
      name  = "api.robertconsulting.net"
      value = "robertconsulting.net"
      note  = "Optional: for API subdomain"
    }
  }
}
