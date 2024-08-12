resource "aws_codestarconnections_connection" "github-cicd" {
  name          = "github-iac-tf-awscicd-demo"
  provider_type = "GitHub"
}