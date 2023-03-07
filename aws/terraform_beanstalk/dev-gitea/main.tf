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

terraform {
  backend "s3" {
    bucket = "gitea-terraform-remote-state"
    key    = "dev/gitea/root/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  env_app = "${var.env}-${var.app}"
}

module "codepipeline" {
   source                  = "../modules/codepipeline"
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
  source                 = "../modules/codebuild"
  codebuild_project_name = "${local.env_app}-proj"
  s3_bucket_name         = module.s3.s3_bucket
}

module "codestar_connection" {
  source = "../modules/codestar_connection"
}

module "iam" {
  source = "../modules/iam"
}

module "s3" {
  source  = "../modules/s3"
  region  = var.region
  env_app = "${local.env_app}"
}

module "beanstalk" {
  source           = "../modules/beanstalk"
  public_subnets   = module.vpc-gitea-dev.public_subnet_ids
  vpc_id           = module.vpc-gitea-dev.vpc_id
  elasticapp       = "${local.env_app}-app"
  beanstalkappenv  = "${local.env_app}-env"
  instance         = "t2.micro"
  autoscaling_min  = 1
  autoscaling_max  = 1
  efs_dns_name     = module.efs.dns_name
  root_url         = "https://${var.app}.aws.eq.org.ua/"
  rds_host         = module.rds.rds_hostname
  rds_user         = module.rds.rds_username
  rds_password     = module.ssm.ssm_rds_password
  rds_db_name      = module.rds.rds_db_name
}

module "vpc-gitea-dev" {
  source                = "../modules/vpc"
  env_app               = "${local.env_app}"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = []
  isolated_subnet_cidrs = var.isolated_subnet_cidrs
}

module "ssm" {
  source = "../modules/ssm"
}

module "rds" {
  source                      = "../modules/rds"
  rds_password                = module.ssm.ssm_rds_password
  database_subnets            = module.vpc-gitea-dev.isolated_subnet_ids
  env_app                     = "${local.env_app}"
  vpc_id                      = module.vpc-gitea-dev.vpc_id
  sg_ingress_database_subnets = var.public_subnet_cidrs
}

module "efs" {
  source = "../modules/efs"
  vpc_id                 = module.vpc-gitea-dev.vpc_id
  name                   = "${local.env_app}-efs"
  subnet_ids             = module.vpc-gitea-dev.isolated_subnet_ids
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

module "route53" {
  source = "../modules/route53"
  zone_name = "aws.eq.org.ua."
  sub_zone  = "${var.app}"
  cname  = module.beanstalk.beanstalk_cname
}
