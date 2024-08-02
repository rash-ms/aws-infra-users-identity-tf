module "github-aws-Idp" {
  source             = "../aws-identity-setup-tf/aws-github-OIDC-auth"
  github-action-name = "GitHubAction-AssumeRole"
  github-action-role-tags = {
    RoleWorkspace-0 = "stg"
    RoleWorkspace-1 = "dev"
    RoleWorkspace-2 = "prod"
  }
  providers = {
    aws = aws.aws-us-east-1
  }
}

