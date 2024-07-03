terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }

  # backend "s3" {}

}

provider "aws" {
  region = "ap-southeast-1"
  #   profile = var.profile
}

# variable "profile" {
#   type    = string
#   default = null
# }