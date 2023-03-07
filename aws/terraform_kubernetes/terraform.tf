terraform {
/*
  cloud {
    workspaces {
      name = "gitea-terraform-eks"
    }
  }
*/
  /*required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.3"
*/
    backend "s3" {
      bucket = "gitea-terraform-remote-state"
      key    = "dev/gitea/kubernetes/terraform.tfstate"
      region = "eu-central-1"
    }

    /*backend "s3" {
       encrypt = true
       bucket = "test-bucket"
       dynamodb_table = "test-ddb"
       region = "us-east-1"
       key = "terraform.tfstate"
     }*/
}

