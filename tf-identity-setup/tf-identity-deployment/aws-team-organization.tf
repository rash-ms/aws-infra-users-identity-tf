module "aws-team-organization" {
  source             = "../aws-orgz-team-unit/"
  # role_tags          = var.role_tags
  teams              = var.teams
  # team_accounts      = var.team_accounts
  # teams_and_accounts = var.teams_and_accounts

  providers = {
    aws = aws.aws-us-east-1
  }
}
