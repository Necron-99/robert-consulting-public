# Outputs for database module

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = var.enable_parameter_group ? aws_db_instance.main_with_params[0].id : aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = var.enable_parameter_group ? aws_db_instance.main_with_params[0].endpoint : aws_db_instance.main.endpoint
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = var.enable_parameter_group ? aws_db_instance.main_with_params[0].port : aws_db_instance.main.port
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = var.enable_parameter_group ? aws_db_instance.main_with_params[0].arn : aws_db_instance.main.arn
}

output "db_username" {
  description = "Username for the database"
  value       = var.db_username
  sensitive   = true
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

output "db_parameter_group_name" {
  description = "Name of the database parameter group"
  value       = aws_db_parameter_group.main.name
}
