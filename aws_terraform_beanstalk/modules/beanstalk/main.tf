# Create elastic beanstalk application
resource "aws_elastic_beanstalk_application" "elasticapp" {
  name = var.elasticapp
}
 
# Create elastic beanstalk Environment
resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                = var.beanstalkappenv
  application         = aws_elastic_beanstalk_application.elasticapp.name
  solution_stack_name = var.solution_stack_name
  tier                = var.tier
 
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     =  "True"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", sort(var.public_subnets))
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internet facing"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.autoscaling_min
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.autoscaling_max
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = var.keypair
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "EFS_NAME"
    value     = var.efs_dns_name
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "EFS_MOUNT_DIR"
    value     = var.efs_mount_dir
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ROOT_URL"
    value     = var.root_url
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOST"
    value     = var.rds_host
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USER"
    value     = var.rds_user
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = var.rds_password
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_DB_NAME"
    value     = var.rds_db_name
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SECRET_KEY"
    value     = var.secret_key
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "LFS_JWT_SECRET"
    value     = var.lfs_jwt_secret
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "INTERNAL_TOKEN"
    value     = var.internal_token
  }
}
