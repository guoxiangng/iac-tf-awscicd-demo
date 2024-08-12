resource "aws_codepipeline" "this" {

  name           = "cp-iac-tf-${var.projectidentifier}-cicd"
  pipeline_type  = "V2"
  execution_mode = "QUEUED" #we dont want to allow concurrent terraform builds of the same TF project. 
  role_arn       = aws_iam_role.codepipeline-cicd.arn

  artifact_store {

    location = aws_s3_bucket.this.id
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.this.id
      type = "KMS"
    }
  }

  # stage {
  #   name = "Source"
  #   action {
  #     name             = "Source"
  #     category         = "Source"
  #     owner            = "AWS"
  #     provider         = "CodeCommit"
  #     version          = "1"
  #     run_order        = 1
  #     output_artifacts = ["SOURCE_ARTIFACT"]
  #     configuration = {
  #       RepositoryName       = aws_codecommit_repository.this.repository_name
  #       BranchName           = "master"
  #       PollForSourceChanges = true
  #       OutputArtifactFormat = "CODE_ZIP"
  #     }
  #   }
  # }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = 1
      output_artifacts = ["SOURCE_ARTIFACT"]
      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github-cicd.arn
        FullRepositoryId       = "guoxiangng/iac-tf-awscicd-demo"
        BranchName           = "master"
        DetectChanges = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "TerraformValidate"
    action {
      name             = "Validate"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 2
      input_artifacts  = ["SOURCE_ARTIFACT"]
      output_artifacts = ["VALIDATE_ARTIFACT"]
      configuration = {
        ProjectName = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACTION"
            value = "VALIDATE"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "TerraformPlan"
    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 2
      input_artifacts  = ["VALIDATE_ARTIFACT"]
      output_artifacts = ["PLAN_ARTIFACT"]
      configuration = {
        ProjectName = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACTION"
            value = "PLAN"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "ApprovalApply"
    action {
      name      = "Apply"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 3
      configuration = {
        NotificationArn = aws_sns_topic.this.arn
      }
    }
  }

  stage {
    name = "TerraformApply"
    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 4
      input_artifacts  = ["PLAN_ARTIFACT"]
      output_artifacts = ["APPLY_ARTIFACT"]
      configuration = {
        ProjectName = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACTION"
            value = "APPLY"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "ApprovalDestroy"
    action {
      name      = "Destroy"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 5
      configuration = {
        NotificationArn = aws_sns_topic.this.arn
      }
    }
  }

  stage {
    name = "TerraformDestroy"
    action {
      name            = "Destroy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      run_order       = 6
      input_artifacts = ["APPLY_ARTIFACT"]
      configuration = {
        ProjectName = aws_codebuild_project.this.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACTION"
            value = "DESTROY"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
  tags = merge(var.additional_tags, )
}



resource "aws_iam_role" "codepipeline-cicd" {
  name = "${var.projectidentifier}-codepipeline-cicd"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
  tags = merge(var.additional_tags, )
}


data "aws_iam_policy_document" "codepipeline-cicd" {
  statement {
    sid = "s3access"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
  }

  statement {
    sid = "codecommitaccess"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive"
    ]

    resources = [aws_codecommit_repository.this.arn]
  }

  statement {
    sid = "codebuildaccess"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [aws_codebuild_project.this.arn]
  }

  statement {
    sid = "snsaccess"
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.this.arn
    ]
  }

  statement {
    sid = "kmsaccess"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_policy" "codepipeline-cicd" {
  name   = "codepipeline-cicd"
  policy = data.aws_iam_policy_document.codepipeline-cicd.json
}

resource "aws_iam_role_policy_attachment" "codepipeline-cicd" {
  role       = aws_iam_role.codepipeline-cicd.name
  policy_arn = aws_iam_policy.codepipeline-cicd.arn
}