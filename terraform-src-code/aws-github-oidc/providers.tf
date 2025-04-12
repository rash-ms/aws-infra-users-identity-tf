terraform {
  required_version = ">=v0.14.7"
  backend "s3" {}
}

provider "aws" {
  alias  = "target"
  region = "us-east-1"

  assume_role {
    role_arn = local.config.target_role_arn
  }
}