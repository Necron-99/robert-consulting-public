# Simplified AWS SES Configuration for robertconsulting.net
# This file configures Simple Email Service without automatic verification

# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = "robertconsulting.net"
}

# SES Domain DKIM
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Route 53 DKIM records for SES
resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = aws_route53_zone.main.zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# Route 53 TXT record for domain verification
resource "aws_route53_record" "ses_verification" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.main.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.main.verification_token]
}

# SES Email Identity for info@robertconsulting.net
resource "aws_ses_email_identity" "info" {
  email = "info@robertconsulting.net"
}

# SES Configuration Set
resource "aws_ses_configuration_set" "main" {
  name = "robertconsulting-email-config"
}

# SES Event Destination for CloudWatch
resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true
  matching_types         = ["send", "reject", "bounce", "complaint", "delivery", "open", "click"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "MessageTag"
    value_source   = "messageTag"
  }
}

# Outputs
output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.main.arn
}

output "ses_domain_verification_token" {
  description = "Domain verification token"
  value       = aws_ses_domain_identity.main.verification_token
  sensitive   = true
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for domain authentication"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "ses_email_identity_arn" {
  description = "ARN of the SES email identity"
  value       = aws_ses_email_identity.info.arn
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}
