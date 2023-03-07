variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "app" {
  description = "Name of application"
  type        = string
  default     = "gitea"
}

variable "env" {
  description = "Name of application"
  type        = string
  default     = "dev"
}


variable "public_subnet_cidrs" {
  description = "Public Networks for each AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private Networks for each AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

