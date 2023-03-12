variable "codebuild_project_name" {
  description = "Default CodeBuild Project"
}

variable "s3_bucket_name" {}

variable "codestar_connection_arn" {}

variable "repository_name" {
  description = "The name of the repository"
  type        = string
  default     = ""
}
