module "github-aws-Idp" {
  source             = "../github-aws-OIDC-Idp"
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