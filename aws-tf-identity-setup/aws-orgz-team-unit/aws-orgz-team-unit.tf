# locals {
#   team_account_emails = jsondecode(file("${path.module}/team_emails.json"))
# }

locals {
  team_account_emails = jsondecode(file("${path.module}/team_emails.json"))
  teams_with_envs = {
    for team in var.teams : team => [
      for env in var.workspace : "${team}-${env}"
    ]
  }
  account_map = {
    for team_env in flatten([for team, envs in local.teams_with_envs : [
      for env in envs : "${team}-${env}"
    ]]) : team_env => team_env
  }
}

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

resource "aws_organizations_organizational_unit" "team" {
  for_each = toset(var.teams)
  name     = each.value
  parent_id = aws_organizations_organization.org.roots[0].id

  tags = {
    Name = "BDT - Data Org - Evergreen Platform - ${each.value}"
  }
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each = local.account_map
  name      = split("-", each.value)[1]
  parent_id = aws_organizations_organizational_unit.team[split("-", each.value)[0]].id

  tags = {
    Name = "BDT - Data Org - Evergreen Platform - ${split("-", each.value)[0]} - ${split("-", each.value)[1]}"
  }
}

resource "aws_organizations_account" "team_env_account" {
  for_each = local.account_map
  name      = "BDT - Data Org - Evergreen Platform - ${each.value}"
  email     = local.team_account_emails.team_account_emails[each.value]
  parent_id = aws_organizations_organizational_unit.team_env[each.value].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name = "BDT - Data Org - Evergreen Platform - ${each.value}",
    Team = split("-", each.value)[0],
    Environment = split("-", each.value)[1]
  }
}


# resource "aws_organizations_organizational_unit" "team" {
#   for_each = toset(var.teams)
#   name     = each.value
#   parent_id = aws_organizations_organization.org.roots[0].id

#   tags = {
#     Name = "BDT - Data Org - Evergreen Platform - ${each.value}"
#   }
# }

# resource "aws_organizations_organizational_unit" "team_env" {
#   for_each = {
#     for team in var.teams : team => [
#       for env in var.workspace : "${team}-${env}"
#     ]
#   }
#   name      = split("-", each.value)[1]
#   parent_id = aws_organizations_organizational_unit.team[split("-", each.value)[0]].id

#   tags = {
#     Name = "BDT - Data Org - Evergreen Platform - ${split("-", each.value)[0]} - ${split("-", each.value)[1]}"
#   }
# }

# resource "aws_organizations_account" "team_env_account" {
#   for_each = {
#     for team in var.teams : [
#       for env in var.workspace : "${team}-${env}"
#     ]
#   }
#   name      = "BDT - Data Org - Evergreen Platform - ${each.value}"
#   email     = local.team_account_emails.team_account_emails[each.value]
#   parent_id = aws_organizations_organizational_unit.team_env[each.value].id
#   role_name = "OrganizationAccountAccessRole"

#   tags = {
#     Name = "BDT - Data Org - Evergreen Platform - ${each.value}",
#     Team = split("-", each.value)[0],
#     Environment = split("-", each.value)[1]
#   }
# }

# data "aws_organizations_organization" "existing" {}

# locals {

#   # Create a list of maps for each team workspace
#   team_env_pairs = flatten([
#     for team in var.teams : [
#       for wrkspc in var.workspace : {
#         team        = team,
#         workspace   = wrkspc
#       }
#     ]
#   ])

#   # create a list of for_each workspace
#   team_wrkspc_map = {
#     for pair in local.team_env_pairs :  
#     "${pair.team}-${pair.workspace}" => {
#       team        = pair.team,
#       workspace   = pair.workspace
#     }
#   }
# }


# resource "aws_organizations_organizational_unit" "team" {
#   for_each = toset(var.teams)

#   name      = each.value
#   parent_id = data.aws_organizations_organization.existing.roots[0].id
# }

# resource "aws_organizations_organizational_unit" "workspace" {
#   for_each = local.team_wrkspc_map

#   name      = each.value.workspace
#   parent_id = aws_organizations_organizational_unit.team[each.value.team].id
# }


