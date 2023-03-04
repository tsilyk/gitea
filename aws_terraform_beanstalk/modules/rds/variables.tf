variable "ssm_password_name" {
  default = "/dev/gitea/mariadb"
}

variable "env_app" {}

variable "rds_password" {}

variable "database_subnets" {}

variable "vpc_id" {}

variable "sg_ingress_database_subnets" {
  default = ["10.0.0.0/16"]
}
