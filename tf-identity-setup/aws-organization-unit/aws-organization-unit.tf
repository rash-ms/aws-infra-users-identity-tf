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

variable "team_accounts" {
  type = map(object({
    name  = string
    email = string
  }))
}

variable "teams" {
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
}

locals {
  all_teams = { for team in var.teams : team.name => team }
}

resource "aws_organizations_organizational_unit" "team" {
  for_each = { for team in var.teams : team.name => team.unit }

  name     = each.value
  parent_id = aws_organizations_organizational_unit.non_prod.id
}

resource "aws_organizations_account" "team_accounts" {
  for_each = {
    for team_name, team in local.all_teams : team_name => team.accounts
  }

  name      = "${team_accounts.value}-${each.key}"
  email     = var.team_accounts[each.key].email
  parent_id = aws_organizations_organizational_unit.team[each.key].id
}

# Define the email addresses for each account in a JSON file
data "external" "team_account_emails" {
  program = ["bash", "-c", "cat ${path.module}/team_account_emails.json"]
}

# Define the teams and their respective accounts
variable "teams_and_accounts" {
  type = list(object({
    name     = string
    unit     = string
    accounts = list(string)
  }))
  default = [
    {
      name     = "prod"
      unit     = aws_organizations_organizational_unit.prod.id
      accounts = ["data-eng-prod", "data-analyst-prod", "data-science-prod"]
    },
    {
      name     = "stg"
      unit     = aws_organizations_organizational_unit.stg.id
      accounts = ["data-eng-stg", "data-analyst-stg", "data-science-stg"]
    },
    {
      name     = "dev"
      unit     = aws_organizations_organizational_unit.dev.id
      accounts = ["data-eng-dev", "data-analyst-dev", "data-science-dev"]
    }
  ]
}

locals {
  accounts = flatten([
    for team in var.teams_and_accounts : [
      for account in team.accounts : {
        name  = account
        email = jsondecode(data.external.team_account_emails.result)[account]
      }
    ]
  ])
}

resource "aws_organizations_account" "accounts" {
  for_each = { for account in local.accounts : account.name => account }

  name       = each.key
  email      = each.value.email
  parent_id  = each.value.unit
}
