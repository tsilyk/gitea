provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "Development"
      Owner       = "Yuriy Tsilyk"
      App         = "Gitea"
      Company     = "SoftServe"
    }
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  env_app = "${var.env}-${var.app}"
}

locals {
  //cluster_name = "${local.env_app}-eks-${random_string.suffix.result}"
  cluster_name = "${local.env_app}-eks"
}

/*resource "random_string" "suffix" {
  length  = 8
  special = false
}*/

module "vpc" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v3.19.0"
  //source  = "terraform-aws-modules/vpc/aws"
  //version = "3.19.0"

  name = "${local.env_app}-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}
/*
module "eks" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v19.10.0"
  //source  = "terraform-aws-modules/eks/aws"
  //version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.25"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
      //remote_access = {
      //  ec2_ssh_key = "MainFrankfurt"
      //}
    }

    two = {
      name = "node-group-2"

      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
      //remote_access = {
      //  ec2_ssh_key = "MainFrankfurt"
      //}
    }
  }
}*/

module "efs" {
  source = "./modules/efs"
  vpc_id                 = module.vpc.vpc_id
  name                   = "${local.env_app}-efs"
  subnet_ids             = module.vpc.private_subnets
  security_group_ingress = {
    default = {
      description = "NFS Inbound"
      from_port   = 2049
      protocol    = "tcp"
      to_port     = 2049
      self        = false
      cidr_blocks = var.public_subnet_cidrs
    }
  }
  lifecycle_policy = [{
    "transition_to_ia" = "AFTER_30_DAYS"
  }]
}

module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source  = "./modules/s3"
  region  = var.region
  env_app = "${local.env_app}"
}

module "codepipeline" {
   source                  = "./modules/codepipeline"
   repository              = "tsilyk/${var.app}"
   name                    = "${local.env_app}-pipeline"
   codebuild_project_name  = module.codebuild.codebuild_project_name
   s3_bucket_name          = module.s3.s3_bucket
   iam_role_arn            = module.iam.role_arn
   codestar_connection_arn = module.codestar_connection.codestar_arn
   elasticapp              = "${local.env_app}-app"
   beanstalkappenv         = "${local.env_app}-env"
 }

module "codebuild" {
  source                  = "./modules/codebuild"
  codebuild_project_name  = "${local.env_app}-proj"
  s3_bucket_name          = module.s3.s3_bucket
  codestar_connection_arn = module.codestar_connection.codestar_arn
  repository_name         = var.app
}

module "codestar_connection" {
  source = "./modules/codestar_connection"
}

module "ecr" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-ecr.git?ref=v1.6.0"

  repository_name = var.app
  repository_image_tag_mutability = "MUTABLE"

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
  }
}

/*
module "build" {
  source = "git::https://github.com/cloudposse/terraform-aws-cicd.git?ref=0.19.5"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  namespace           = "ss"
  stage               = "dev"
  name                = var.app

  # Enable the pipeline creation
  enabled             = true

  # Elastic Beanstalk
  //elastic_beanstalk_application_name = "<(Optional) Elastic Beanstalk application name>"
  //elastic_beanstalk_environment_name = "<(Optional) Elastic Beanstalk environment name>"

  # Application repository on GitHub
  github_oauth_token  = "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"
  repo_owner          = "tsilyk"
  repo_name           = "gitea"
  branch              = "main"

  codestar_connection_arn = module.codestar_connection.codestar_arn

  # http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html
  # http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
  build_image         = "aws/codebuild/standard:2.0"
  build_compute_type  = "BUILD_GENERAL1_SMALL"

  # These attributes are optional, used as ENV variables when building Docker images and pushing them to ECR
  # For more info:
  # http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html
  # https://www.terraform.io/docs/providers/aws/r/codebuild_project.html
  privileged_mode     = true
  region              = var.region
  aws_account_id      = "085054811666"
  image_repo_name     = var.app
  image_tag           = "latest"

  # Optional extra environment variables
  environment_variables = [{
    name  = "JENKINS_URL"
    value = "https://jenkins.example.com"
  },
  {
    name  = "COMPANY_NAME"
    value = "Amazon"
  },
  {
    name = "TIME_ZONE"
    value = "Pacific/Auckland"
  }]
}*/

