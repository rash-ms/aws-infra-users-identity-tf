module "aws-team-organization" {
  source              = "../aws-orgz-team-unit"
  teams               = var.teams 
  workspace           = var.workspace
  environment         = var.environment

  #   teams              = var.teams

  # role_tags          = var.role_tags
  # team_accounts      = var.team_accounts
  # teams_and_accounts = var.teams_and_accounts

  providers = {
    aws = aws.aws-us-east-1
  }
}
