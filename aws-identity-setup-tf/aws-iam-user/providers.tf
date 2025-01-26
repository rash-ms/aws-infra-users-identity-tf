terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket = "byt-infra-user-identity-backend"
    key    = "aws-orgz-team-unit/${var.environment}/aws-iam-user.tfstate"
    region = "us-east-1"
  }
}