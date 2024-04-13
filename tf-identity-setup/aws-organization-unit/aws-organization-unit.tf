resource "aws_organizations_organization" "organization" {}

resource "aws_organizations_organizational_unit" "data_team" {
  name     = "data-team"
  parent_id = aws_organizations_organization.organization.id
}

resource "aws_organizations_organizational_unit" "prod" {
  name     = "Prod"
  parent_id = aws_organizations_organizational_unit.data_team.id
}

resource "aws_organizations_organizational_unit" "non_prod" {
  name     = "Non-prod"
  parent_id = aws_organizations_organizational_unit.data_team.id
}

resource "aws_organizations_organizational_unit" "stg" {
  name     = "stg"
  parent_id = aws_organizations_organizational_unit.non_prod.id
}

resource "aws_organizations_organizational_unit" "dev" {
  name     = "dev"
  parent_id = aws_organizations_organizational_unit.non_prod.id
}

# locals {
#   all_teams = { for team in var.teams : team.name => team }
# }

# resource "aws_organizations_organizational_unit" "team" {
#   for_each = { for team in var.teams : team.name => team.unit }

#   name     = each.value
#   parent_id = aws_organizations_organizational_unit.non_prod.id
# }

# resource "aws_organizations_account" "team_accounts" {
#   for_each = {
#     for team_name, team in local.all_teams : team_name => team.accounts
#   }

#   name      = "${team_accounts.value}-${each.key}"
#   email     = var.team_accounts[each.key].email
#   parent_id = aws_organizations_organizational_unit.team[each.key].id
# }

# # Define the email addresses for each account in a JSON file
# data "external" "team_account_emails" {
#   program = ["bash", "-c", "cat ${path.module}/team_account_emails.json"]
# }

# locals {
#   accounts = flatten([
#     for team in var.teams_and_accounts : [
#       for account in team.accounts : {
#         name  = account
#         email = jsondecode(data.external.team_account_emails.result)[account]
#       }
#     ]
#   ])
# }

# resource "aws_organizations_account" "accounts" {
#   for_each = { for account in local.accounts : account.name => account }

#   name       = each.key
#   email      = each.value.email
#   parent_id  = each.value.unit
# }
