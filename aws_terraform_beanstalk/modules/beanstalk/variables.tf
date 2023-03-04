variable "elasticapp" {
  description = "ElasticBeanstalk application name"
  default     = "app"
}
variable "beanstalkappenv" {
  description = "ElasticBeanstalk environment name"
  default     = "app-env"
}
variable "solution_stack_name" {
  description = "Get list: aws elasticbeanstalk list-available-solution-stacks"
  default     = "64bit Amazon Linux 2 v3.6.4 running Go 1"
}
variable "tier" {
  default = "WebServer"
}
variable "vpc_id" {
}
variable "public_subnets" {
}
variable "keypair" {
  default = "MainFrankfurt"
}
variable "instance" {
  default = "t2.micro"
}
variable "autoscaling_min" {
  description = "Autoscaling min hosts"
  default     = 1
}
variable "autoscaling_max" {
  description = "Autoscaling max hosts"
  default     = 1
}
variable "efs_dns_name" {
  description = "EFS DNS name"
}
variable "efs_mount_dir" {
  description = "EFS mount directory"
  default     = "/mnt"
}
variable "root_url" {
  description = "Application url"
  default     = "localhost"
}
variable "rds_host" {
  description = "DRS hostname"
  default     = "localhost"
}
variable "rds_user" {
  description = "RDS username"
  default     = "user"
}
variable "rds_password" {
  description = "RDS password"
  default     = "password"
}
variable "rds_db_name" {
  description = "RDS database name"
  default     = "db"
}
variable "secret_key" {
  description = "Key for encription data in application"
  default     = "mDgQaX3xau4a6bBIMLeTESgwhBNTurDjotJbyznee0UKD7SBpVP2Plhtg4jMHfOH"
}
variable "lfs_jwt_secret" {
  description = "Lage file system secret key"
  default     = "8yEmrJbE7iKQzXEwU1QlZgZZAw4WwwTzQv7pn_NV-K8"
}
variable "internal_token" {
  description = "Internal Token"
  default     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYmYiOjE2NzcwNzU2Nzd9.cBFlYPDgZQNJd5wDYFAa_Sp_GEY6U-nooAvsfRWT4sI"
}
