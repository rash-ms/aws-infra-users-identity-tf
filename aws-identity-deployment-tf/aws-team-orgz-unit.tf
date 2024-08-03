terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "byt-infra-users-identity-backend"
    key            = "terraform/complete-state"
    region         = "us-east-1"                
  }
}

module "aws-team-orgz-unit" {
  source              = "../aws-identity-setup-tf/aws-orgz-team-unit"
  teams               = var.teams 
  workspace           = var.workspace

  providers = {
    aws = aws.aws-us-east-1
  }
}
