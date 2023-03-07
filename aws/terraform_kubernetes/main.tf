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
  cluster_version = "1.24"

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
}

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
