resource "aws_codebuild_project" "CodeBuild_Project" {
    name                   = var.codebuild_project_name
    encryption_key         = aws_kms_key.codebuild.arn
    service_role           = aws_iam_role.codebuildrole.arn

    artifacts {
        name                   = var.codebuild_project_name
        override_artifact_name = false
        packaging              = "ZIP"
        type                   = "CODEPIPELINE"
    }

   cache {
     type  = "LOCAL"
     modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
   }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
        image_pull_credentials_type = "CODEBUILD"
        type                        = "LINUX_CONTAINER"
        privileged_mode             = true
        environment_variable {
          name  = "AWS_ACCOUNT_ID"
          value = "${data.aws_caller_identity.default.account_id}"
        }
        environment_variable {
          name  = "IMAGE_REPO_NAME"
          value = "${var.repository_name}"
        }
        environment_variable {
          name  = "NAMESPACE"
          value = "gitea-testing"
        }
        environment_variable {
          name  = "DEPLOYMENT"
          value = "gitea"
        }
    }

    logs_config {
        cloudwatch_logs {
            status = "ENABLED"
        }
    }

    source {
        git_clone_depth     = 0
        type                = "CODEPIPELINE"
    }
}

resource "aws_kms_key" "codebuild" {
    description              = "Default master key that protects my S3 objects when no other key is defined"
    enable_key_rotation      = true
    policy                   = jsonencode(
        {
            Id        = "auto-s3"
            Statement = [
                {
                    Action    = [
                        "kms:Encrypt",
                        "kms:Decrypt",
                        "kms:ReEncrypt*",
                        "kms:GenerateDataKey*",
                        "kms:DescribeKey",
                    ]
                    Condition = {
                        StringEquals = {
                            "kms:CallerAccount" = ["${data.aws_caller_identity.default.account_id}"]
                            "kms:ViaService"    = "s3.eu-central-1.amazonaws.com"
                        }
                    }
                    Effect    = "Allow"
                    Principal = {
                        AWS = "*"
                    }
                    Resource  = "*"
                    Sid       = "Allow access through S3 for all principals in the account that are authorized to use S3"
                },
                {
                    Action    = [
                        "kms:*",
                    ]
                    Effect    = "Allow"
                    Principal = {
                        AWS = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
                    }
                    Resource  = "*"
                    Sid       = "Allow direct access to key metadata to the account"
                },
            ]
            Version   = "2012-10-17"
        }
    )
}


resource "aws_iam_role" "codebuildrole" {
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = [
                          "codepipeline.amazonaws.com", 
                          "codebuild.amazonaws.com", 
                          "eks.amazonaws.com"
                        ]
                    }
                },
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                      AWS = [
                        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:user/terraform",
                        #https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/
                        "arn:aws:iam::${data.aws_caller_identity.default.account_id}:role/CodeBuildRole",
                        //"arn:aws:sts::085054811666:assumed-role/CodeBuildRole/codebuild-kubectl"
                    ]
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    description           = "Allows CodeBuild to call AWS services on your behalf."
    force_detach_policies = false
    managed_policy_arns   = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    ]
    max_session_duration  = 3600
    name                  = "CodeBuildRole"

    inline_policy {
        name   = "CodeBuild"
        policy = jsonencode(
            {
                Statement = [
                    {
                        Action   = [
                            "logs:CreateLogGroup",
                            "logs:CreateLogStream",
                            "logs:PutLogEvents",
                        ]
                        Effect   = "Allow"
                        Resource = [
                            "*",
                        ]
                    },
                    {
                        Action   = [
                            "s3:PutObject",
                            "s3:GetObject",
                            "s3:GetObjectVersion",
                            "s3:GetBucketAcl",
                            "s3:GetBucketLocation",
                        ]
                        Effect   = "Allow"
                        Resource = [
                            "arn:aws:s3:::${var.s3_bucket_name}",
                        ]
                    },
                    {
                        Action   = [
                            "lambda:GetAlias",
                            "lambda:ListVersionsByFunction",
                        ]
                        Effect   = "Allow"
                        Resource = [
                            "*",
                        ]
                    },
                    {
                        Action   = [
                            "cloudformation:GetTemplate",
                        ]
                        Effect   = "Allow"
                        Resource = [
                            "*",
                        ]
                    },
                    {
                        Action   = [
                            "codebuild:CreateReportGroup",
                            "codebuild:CreateReport",
                            "codebuild:UpdateReport",
                            "codebuild:BatchPutTestCases",
                            "codebuild:BatchPutCodeCoverages",
                        ]
                        Effect   = "Allow"
                        Resource = [
                            "*",
                        ]
                    },
                    {
                      "Sid": "EKSAccessPolicy",
                      "Effect": "Allow",
                      "Action": [
                        "eks:*"
                      ],
                      "Resource": "*"
                    },
                    {
                      Action   = [
                            "codestar-connections:UseConnection",
                        ]
                        Effect   = "Allow",
                        Resource = [
                            var.codestar_connection_arn,
                        ]
                    }
                ]
                Version   = "2012-10-17"
            }
        )
    }
}

resource "aws_kms_alias" "codebuild" {
    name           = "alias/codepipelinekey"
    target_key_id  = aws_kms_key.codebuild.key_id
}

data "aws_caller_identity" "default" {}
