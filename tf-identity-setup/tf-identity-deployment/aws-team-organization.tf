module "aws-team-organization" {
  source              = "../aws-orgz-team-unit"
  teams               = var.teams 
  common_environments = var.common_environments
  sub_environments    = var.sub_environments

  #   teams              = var.teams

  # role_tags          = var.role_tags
  # team_accounts      = var.team_accounts
  # teams_and_accounts = var.teams_and_accounts

  providers = {
    aws = aws.aws-us-east-1
  }
}
