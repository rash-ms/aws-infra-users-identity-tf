terraform {
  required_version = ">=v0.14.7"
  backend "s3" {}
}

provider "aws" {
  alias  = "dev"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::273354624134:role/byt-dev-CrossAccountAdminRole"
    session_name = "byt-iam-user-dev-session"
  }
}

provider "aws" {
  alias  = "prod"
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::277707114319:role/byt-prod-CrossAccountAdminRole"
    session_name = "byt-iam-user-prod-session"
  }
}
