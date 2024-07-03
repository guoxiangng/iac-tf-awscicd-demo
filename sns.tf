#-------------------------------------------------------------------------------
# SNS Topic 

resource "aws_sns_topic" "this" {
  name         = "${var.projectidentifier}-tf_cicd_notif"
  display_name = "${var.projectidentifier}-tf_cicd_notif"
  tags         = merge(var.additional_tags, )
}

# SNS Topic Policy

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns.json
}

data "aws_iam_policy_document" "sns" {
  statement {
    actions = [
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    resources = [
      aws_sns_topic.this.arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_codepipeline.this.arn]
    }
  }
}

#-------------------------------------------------------------------------------
# SNS Subscription

# resource "aws_sns_topic_subscription" "this" {
#   topic_arn = aws_sns_topic.this.arn
#   protocol  = 
#   endpoint  = 
# }