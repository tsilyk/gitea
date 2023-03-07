output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.app_database.address
  sensitive   = true
}
output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.app_database.port
  sensitive   = true
}
output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.app_database.username
  sensitive   = true
}
output "rds_db_name" {
  description = "RDS The database name"
  value       = aws_db_instance.app_database.db_name
  sensitive   = true
}
