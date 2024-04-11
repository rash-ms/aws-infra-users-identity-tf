provider "aws" {
  alias  = "aws-us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "aws-us-east-2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "aws-eu-west-1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "aws-eu-central-1"
  region = "eu-central-1"
}

terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "ms-data-infra-backend"
    key            = "terraform/complete-state"
    region         = "us-east-1"                
  }
}
