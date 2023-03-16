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

module "eks" {
  source  = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v19.10.0"
  //source  = "terraform-aws-modules/eks/aws"
  //version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.25"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 1
      //remote_access = {
      //  ec2_ssh_key = "MainFrankfurt"
      //}
    }

    two = {
      name = "node-group-2"

      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
      //remote_access = {
      //  ec2_ssh_key = "MainFrankfurt"
      //}
    }
  }
}

module "efs" {
  source                  = "./modules/efs"
  vpc_id                  = module.vpc.vpc_id
  name                    = "${local.env_app}-efs"
  subnet_ids              = module.vpc.private_subnets

  cluster_name                       = module.eks.cluster_name
  cluster_oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_id                         = module.eks.cluster_id
  
  security_group_ingress = {
    default = {
      description = "NFS Inbound"
      from_port   = 2049
      protocol    = "tcp"
      to_port     = 2049
      self        = false
      cidr_blocks = var.private_subnet_cidrs
    }
  }
  lifecycle_policy = [{
    "transition_to_ia" = "AFTER_30_DAYS"
  }]
  //depends_on = [
  //  module.eks
  //]
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
  manage_registry_scanning_configuration = false

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

module "ssm" {
	source = "./modules/ssm"
}

module "rds" {
	source                      = "./modules/rds"
	rds_password                = module.ssm.ssm_rds_password
	database_subnets            = module.vpc.private_subnets
	env_app                     = "${local.env_app}"
	vpc_id                      = module.vpc.vpc_id
	sg_ingress_database_subnets = module.vpc.private_subnets_cidr_blocks
}

/*module "external_param" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-external-secrets.git?ref=0.1.3"

  enabled = true

  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  secrets_aws_region               = var.region
  //namespace                        = "kube-system"
}*/

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1"
      args        = ["eks", "get-token", "--cluster-name", "${module.eks.cluster_name}"]
      command     = "aws"
    }
  }
}

/*
data "aws_eks_cluster" "eks" {
  //name = module.eks.cluster_id
  name = module.eks.cluster_name
	depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  //name = module.eks.cluster_id
  name = module.eks.cluster_name
	depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}*/

/*
module "external_secrets" {
  source                = "github.com/andreswebs/terraform-aws-eks-external-secrets"
  //cluster_oidc_provider = module.eks.oidc_provider
  cluster_oidc_provider = module.eks.cluster_oidc_issuer_url
  iam_role_name         = "external-secrets-${module.eks.cluster_name}"
  secret_names = [
    "password",
    "token",
    "etc"
  ]
}*/

/*
module "cluster" {
  source = "./modules/external-params"

  cluster_name      = module.eks.cluster_name
  cluster_region    = var.region
  irsa_sa_name      = "external-params"
  irsa_sa_namespace = "external-params"
}
*/
module "k8s" {
  source           = "./modules/kubernetes"
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_cert  = module.eks.cluster_certificate_authority_data
  cluster_name     = module.eks.cluster_name
  efs_id           = module.efs.efs_id
  efs_ap_id        = module.efs.efs_ap_id
  rds_hostname     = module.rds.rds_hostname
  rds_username     = module.rds.rds_username
  rds_db_name      = module.rds.rds_db_name
	rds_password     = module.ssm.ssm_rds_password
}
