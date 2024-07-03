#-------------------------------------------------------------------------------
# Codebuild

resource "aws_codebuild_project" "this" {
  name                   = "cb-iac-tf-${var.projectidentifier}"
  service_role           = aws_iam_role.codebuild.arn
  concurrent_build_limit = 1

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "prownage/aws-codebuild-terraform:latest"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yaml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }
  }
  tags = merge(var.additional_tags, )
}


resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/codebuild/${var.projectidentifier}"
  retention_in_days = 7
  tags              = merge(var.additional_tags, )
}


resource "aws_iam_role" "codebuild" {
  name = "${var.projectidentifier}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
  tags = merge(var.additional_tags, )
}

#Attach policy with current account deployment permissions
resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#Attach policy with acc1 (cross account) deployment permissions
resource "aws_iam_role_policy_attachment" "codebuild2" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.assume_role_policy_acc1deploy.arn
}

resource "aws_iam_policy" "assume_role_policy_acc1deploy" {
  name        = "assume_role_policy_for_acc_395890110782"
  description = "Assume Role permission for AccountId 395890110782"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "arn:aws:iam::395890110782:role/lzdemo-crossacc-tfdeploy",
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "lzdemo"
        }
      }
    }
  ]
}
EOF
}