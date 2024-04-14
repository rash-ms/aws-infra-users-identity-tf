data "aws_organizations_organization" "existing" {}

locals {
  # Create a list of maps for each team-environment pair
  team_env_pairs = flatten([
    for team in var.teams : [
      for env in var.common_environments : {
        team        = team,
        environment = env
      }
    ]
  ])

  # Create a list of maps for each team-environment-sub_environment trio where the environment is Non-prod
  team_sub_env_pairs = flatten([
    for team in var.teams : [
      for sub_env in var.sub_environments : {
        team           = team,
        environment    = "Non-prod",
        sub_environment = sub_env
      }
    ]
  ])
  
  # Convert the list of maps into a map for for_each for the environments
  team_env_map = {
    for pair in team_env_pairs :  # Removed 'locals.' prefix
    "${pair.team}-${pair.environment}" => {
      team        = pair.team,
      environment = pair.environment
    }
  }
  
  # Convert the list of maps into a map for for_each for the sub-environments
  team_sub_env_map = {
    for pair in team_sub_env_pairs :  # Removed 'locals.' prefix
    "${pair.team}-${pair.environment}-${pair.sub_environment}" => {
      team           = pair.team,
      environment    = pair.environment,
      sub_environment = pair.sub_environment
    }
  }
}


resource "aws_organizations_organizational_unit" "team" {
  for_each = toset(var.teams)

  name      = each.value
  parent_id = data.aws_organizations_organization.existing.roots[0].id
}

resource "aws_organizations_organizational_unit" "environment" {
  for_each = local.team_env_map

  name      = each.value.environment
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id
}

resource "aws_organizations_organizational_unit" "sub_environment" {
  for_each = local.team_sub_env_map

  name      = each.value.sub_environment
  parent_id = aws_organizations_organizational_unit.environment["${each.value.team}-Non-prod"].id
}
