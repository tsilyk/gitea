output "efs_dns_name" {
  value       = module.efs.dns_name
  description = "EFS DNS name"
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = module.rds.rds_hostname
  sensitive   = true
}

output "beanstalk_endpoint_url" {
  description = "The URL to the Load Balancer for this Environment"
  value       = module.beanstalk.beanstalk_endpoint_url
}

output "beanstalk_cname" {
  description = "Fully qualified DNS name for this Environment"
  value       = module.beanstalk.beanstalk_cname
}
output "beanstalk_launch_configurations" {
  description = "Launch configurations in use by this Environment"
  value       = module.beanstalk.beanstalk_launch_configurations
}

