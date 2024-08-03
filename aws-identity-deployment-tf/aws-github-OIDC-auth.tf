terraform {
  required_version = ">=v0.14.7"
  backend "s3" {
    bucket         = "bdt-infra-resource-backend"
    key            = "terraform/complete-state"
    region         = "us-east-1"                
  }
}

module "aws-github-OIDC-auth" {
  source             = "../aws-identity-setup-tf/aws-github-OIDC-auth"
  github_action_name    = var.github_action_name
  github_action_role_tags = var.github_action_role_tags

  providers = {
    aws = aws.aws-us-east-1
  }
}