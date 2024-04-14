resource "aws_organizations_organization" "organization" {}

resource "aws_organizations_organizational_unit" "data_team" {
  name      = "data-team"
  parent_id = aws_organizations_organization.organization.id
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.data_team.id
}

resource "aws_organizations_organizational_unit" "non_prod" {
  name      = "Non-prod"
  parent_id = aws_organizations_organizational_unit.data_team.id
}

resource "aws_organizations_organizational_unit" "stg" {
  name      = "stg"
  parent_id = aws_organizations_organizational_unit.non_prod.id
}

resource "aws_organizations_organizational_unit" "dev" {
  name      = "dev"
  parent_id = aws_organizations_organizational_unit.non_prod.id
}

# locals {
#   all_teams = { for team in var.teams : team.name => team }
# }

# resource "aws_organizations_organizational_unit" "team" {
#   for_each = locals.all_teams
#   name     = each.key
#   parent_id = aws_organizations_organizational_unit.non_prod.id
# }

# resource "aws_organizations_account" "team_accounts" {
#   for_each = local.all_teams
#   name     = "${each.key}-account"
#   email    = var.team_accounts[each.key].email
#   parent_id = aws_organizations_organizational_unit.team[each.key].id
# }

# data "external" "team_account_emails" {
#   program = ["bash", "-c", "cat ${path.module}/team_account_emails.json"]
# }

# locals {
#   accounts = flatten([
#     for team in var.teams : [
#       for account in team.accounts : {
#         name  = account
#         email = jsondecode(data.external.team_account_emails.result)[account]
#         unit  = aws_organizations_organizational_unit.team[team.name].id
#       }
#     ]
#   ])
# }

# resource "aws_organizations_account" "accounts" {
#   for_each = { for account in local.accounts : account.name => account }
#   name     = each.key
#   email    = each.value.email
#   parent_id = each.value.unit
# }

variable "teams" {
  description = "List of teams with their unit and organizational details"
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

variable "team_accounts" {
  description = "Map of team accounts with names and email addresses"
  type = map(object({
    name  = string
    email = string
  }))
}

variable "teams_and_accounts" {
  description = "List of teams and their account details"
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

variable "role_tags" {
  description = "List of role tags used for differentiating environment roles"
  type        = list(string)
  default     = ["stg", "dev", "prod"]
}
