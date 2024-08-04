provider "aws" {
  alias  = "aws-us-east-1"
  region = "us-east-1"
}

terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "byt-infra-user-identity-backend"
    key            = "aws-orgz-team-unit/terraform.tfstate"
    # key            = "complete-state/terraform.tfstate"
    region         = "us-east-1"                
  }
}
