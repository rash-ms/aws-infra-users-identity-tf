locals {
  team_account_emails = jsondecode(file("${path.module}/team_emails.json")).team_account_emails
  team_env_pairs = flatten([
      for team in var.teams : [
        for env in var.workspace : {
          team = team,
          env  = env
        }
      ]
    ])

    account_map = {
      for pair in local.team_env_pairs : 
      "${pair.team}-${pair.env}" => pair
    }
 }


data "aws_organizations_organization" "existing" {}

# resource "aws_organizations_organization" "org" {
#   aws_service_access_principals = [
#     "cloudtrail.amazonaws.com",
#     "config.amazonaws.com",
#   ]

#   enabled_policy_types = [
#     "SERVICE_CONTROL_POLICY"
#   ]
# }

resource "aws_organizations_organizational_unit" "team" {
  for_each = toset(var.teams)
  name     = each.value
  # parent_id = aws_organizations_organization.org.roots[0].id
  parent_id = data.aws_organizations_organization.existing.roots[0].id

  tags = {
    Name = "BDT - ${each.value}"
  }
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each = local.account_map
  name      = each.value.env
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id

  tags = {
    Name = "BDT - ${each.value.team} - ${each.value.env}"
  }
}

resource "aws_organizations_account" "team_env_account" {
  for_each = local.account_map
  name      = "BDT - ${each.key}"
  email     = local.team_account_emails[each.key]
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name = "BDT -  ${each.key}",
    Team = each.value.team,
    Environment = each.value.env
  }
}