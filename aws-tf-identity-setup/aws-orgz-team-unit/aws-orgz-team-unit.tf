data "aws_organizations_organization" "existing" {}

locals {

  # Create a list of maps for each team workspace
  team_env_pairs = flatten([
    for team in var.teams : [
      for wrkspc in var.workspace : {
        team        = team,
        workspace   = wrkspc
      }
    ]
  ])

  # create a list of for_each workspace
  team_wrkspc_map = {
    for pair in local.team_env_pairs :  
    "${pair.team}-${pair.workspace}" => {
      team        = pair.team,
      workspace   = pair.workspace
    }
  }
}


resource "aws_organizations_organizational_unit" "team" {
  for_each = toset(var.teams)

  name      = each.value
  parent_id = data.aws_organizations_organization.existing.roots[0].id
}

resource "aws_organizations_organizational_unit" "workspace" {
  for_each = local.team_wrkspc_map

  name      = each.value.workspace
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id
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

