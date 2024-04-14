data "aws_organizations_organization" "existing" {}

variable "teams" {
  type    = list(string)
  default = ["data-team", "security-team", "marketing-team"]
}

locals {
  common_environments = ["Prod", "Non-prod"]
  sub_environments    = ["dev", "stg"]

  # Flatten into a list of maps
  team_env_pairs = flatten([
    for team in var.teams : [
      for env in locals.common_environments : {
        "team"        = team,
        "environment" = env
      }
    ]
  ])

  # Convert the list of maps into a map for for_each
  team_env_map = {
    for pair in local.team_env_pairs :
    "${pair.team}-${pair.environment}" => {
      team        = pair.team,
      environment = pair.environment
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
