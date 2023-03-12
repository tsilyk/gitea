resource "aws_codepipeline" "pipeline" {
  name = "${var.name}"
  role_arn = var.iam_role_arn

  artifact_store {
    location = var.s3_bucket_name
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${var.repository}"
        BranchName           = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build_and_Tests"
    action {
      name             = "Build_and_Tests"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "${var.codebuild_project_name}"
      }
    }
  }

/*  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ElasticBeanstalk"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ApplicationName = "${var.elasticapp}"
        EnvironmentName = "${var.beanstalkappenv}"
      }
    }
  }*/


    /*stage {
       name = "Manual_Approval"
       action {
         name     = "Manual-Approval"
         category = "Approval"
         owner    = "AWS"
         provider = "Manual"
         version  = "1"
       }
     }*/

}
