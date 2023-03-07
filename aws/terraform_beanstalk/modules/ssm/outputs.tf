output "ssm_rds_password" {
  value     = data.aws_ssm_parameter.rds_password.value
  sensitive = true
}
