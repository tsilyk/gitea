output "beanstalk_endpoint_url" {
  description = " The URL to the Load Balancer for this Environment"
  value       = aws_elastic_beanstalk_environment.beanstalkappenv.endpoint_url
}
output "beanstalk_cname" {
  description = "Fully qualified DNS name for this Environment"
  value       = aws_elastic_beanstalk_environment.beanstalkappenv.cname
}
output "beanstalk_launch_configurations" {
  description = "Launch configurations in use by this Environment"
  value       = aws_elastic_beanstalk_environment.beanstalkappenv.launch_configurations
}
