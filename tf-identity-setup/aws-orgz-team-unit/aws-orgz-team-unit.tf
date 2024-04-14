data "aws_organizations_organization" "existing" {}

variable "teams" {
  description = "Map of teams to their environments and sub-environments."
  type = map(object({
    prod_sub_ous = list(string)
    non_prod_sub_ous = list(string)
  }))

  default = {
    "data-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
    "security-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
    "marketing-team" = {
      prod_sub_ous = [],
      non_prod_sub_ous = ["dev", "stg"]
    },
  }
}

# Create OUs for each team
resource "aws_organizations_organizational_unit" "team" {
  for_each = var.teams

  name      = each.key
  parent_id = data.aws_organizations_organization.existing.roots[0].id
}

# Create Prod OUs for each team
resource "aws_organizations_organizational_unit" "prod" {
  for_each = var.teams

  name      = "Prod"
  parent_id = aws_organizations_organizational_unit.team[each.key].id
}

# Create Non-Prod OUs for each team
resource "aws_organizations_organizational_unit" "non_prod" {
  for_each = var.teams

  name      = "Non-prod"
  parent_id = aws_organizations_organizational_unit.team[each.key].id
}

# Create sub-ous for Prod environment for each team (if any)
resource "aws_organizations_organizational_unit" "prod_sub_ous" {
  for_each = toset(flatten([
    for team, detail in var.teams : [
      for sub_ou in detail.prod_sub_ous : {
        team_name = team
        sub_ou_name = sub_ou
      }
    ]
  ]))

  name      = each.value.sub_ou_name
  parent_id = aws_organizations_organizational_unit.prod[each.value.team_name].id
}

# Create sub-ous for Non-Prod environment for each team
resource "aws_organizations_organizational_unit" "non_prod_sub_ous" {
  for_each = toset(flatten([
    for team, detail in var.teams : [
      for sub_ou in detail.non_prod_sub_ous : {
        team_name = team
        sub_ou_name = sub_ou
      }
    ]
  ]))

  name      = each.value.sub_ou_name
  parent_id = aws_organizations_organizational_unit.non_prod[each.value.team_name].id
}



# resource "aws_organizations_organizational_unit" "data_team" {
#   name      = "data-team"
#   parent_id = data.aws_organizations_organization.existing.roots[0].id
# }

# resource "aws_organizations_organizational_unit" "prod" {
#   name      = "Prod"
#   parent_id = aws_organizations_organizational_unit.data_team.id
# }

# resource "aws_organizations_organizational_unit" "non_prod" {
#   name      = "Non-prod"
#   parent_id = aws_organizations_organizational_unit.data_team.id
# }

# resource "aws_organizations_organizational_unit" "stg" {
#   name      = "stg"
#   parent_id = aws_organizations_organizational_unit.non_prod.id
# }

# resource "aws_organizations_organizational_unit" "dev" {
#   name      = "dev"
#   parent_id = aws_organizations_organizational_unit.non_prod.id
# }

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

# variable "teams" {
#   description = "List of teams with their unit and organizational details"
#   type = list(object({
#     name     = string
#     unit     = string
#     accounts = list(string)
#   }))
# }

# variable "team_accounts" {
#   description = "Map of team accounts with names and email addresses"
#   type = map(object({
#     name  = string
#     email = string
#   }))
# }

# variable "teams_and_accounts" {
#   description = "List of teams and their account details"
#   type = list(object({
#     name     = string
#     unit     = string
#     accounts = list(string)
#   }))
# }

# variable "role_tags" {
#   description = "List of role tags used for differentiating environment roles"
#   type        = list(string)
#   default     = ["stg", "dev", "prod"]
# }
