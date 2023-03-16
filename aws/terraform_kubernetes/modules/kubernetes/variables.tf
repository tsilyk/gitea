variable "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
}

variable "cluster_ca_cert" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
}

variable "efs_id" {
  description = "EFS ID"
}

variable "efs_ap_id" {
  description = "EFS AP ID"
}

variable "rds_hostname" {
  description = "RDS instance hostname"
}

variable "rds_password" {
  description = "RDS instance ppassword"
}

variable "rds_username" {
  description = "RDS instance root username"
}

variable "rds_db_name" {
  description = "RDS The database name"
}
