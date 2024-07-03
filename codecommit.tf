resource "aws_codecommit_repository" "this" {
  repository_name = "cc-iac-tf-${var.projectidentifier}-cicd"
  description     = ""
  kms_key_id      = aws_kms_key.this.arn
  tags            = merge(var.additional_tags, )
}
resource "aws_codecommit_repository" "this2" {
  repository_name = "cc-iac-tf-${var.projectidentifier}-acc1"
  description     = "Test Repo with resources to be deployed into another account"
  kms_key_id      = aws_kms_key.this.arn
  tags            = merge(var.additional_tags, )
}