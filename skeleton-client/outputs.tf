# Outputs for the infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "database_port" {
  description = "Port of the RDS instance"
  value       = module.database.db_instance_port
}

output "database_arn" {
  description = "ARN of the RDS instance"
  value       = module.database.db_instance_arn
}

output "app_data_bucket_name" {
  description = "Name of the app data S3 bucket"
  value       = module.storage.app_data_bucket_name
}

output "static_assets_bucket_name" {
  description = "Name of the static assets S3 bucket"
  value       = module.storage.static_assets_bucket_name
}

output "backups_bucket_name" {
  description = "Name of the backups S3 bucket"
  value       = module.storage.backups_bucket_name
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.storage.cloudfront_distribution_domain_name
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = var.environment == "production" ? aws_lb.main[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = var.environment == "production" ? aws_lb.main[0].zone_id : null
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "client_name" {
  description = "Client name"
  value       = var.client_name
}
