# module "aws-team-organization" {
#   source             = "../aws-orgz-team-unit/"
#   teams              = var.teams

#   # role_tags          = var.role_tags
#   # team_accounts      = var.team_accounts
#   # teams_and_accounts = var.teams_and_accounts

#   providers = {
#     aws = aws.aws-us-east-1
#   }
# }


module "aws-team-organization" {
  source = "../aws-orgz-team-unit"
  teams  = ["data-team", "security-team", "marketing-team"]

  providers = {
    aws = aws.aws-us-east-1
  }
}
