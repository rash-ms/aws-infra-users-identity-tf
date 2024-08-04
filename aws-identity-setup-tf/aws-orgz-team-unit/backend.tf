terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "byt-infra-users-identity-backend"
    key            = "aws-orgz-team-unit/terraform.tfstate"
    region         = "us-east-1"                
  }
}
