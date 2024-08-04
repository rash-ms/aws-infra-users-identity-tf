locals {
  team_account_emails = jsondecode(file("${path.module}/aws_team_emails.json")).emails
  policies            = jsondecode(file("${path.module}/policies.json"))
  groups              = local.policies.groups

  team_env_pairs = flatten([
    for team in var.teams : [
      for env in var.workspace : {
        team = team,
        env  = env
      }
    ]
  ])

  created_teams = { for k, v in aws_organizations_organizational_unit.team : k => v.id }

  account_map = {
    for pair in local.team_env_pairs :
    "${pair.team}-${pair.env}" => pair
    if contains(keys(local.created_teams), pair.team)
  }

  readonly_permission_sets = {
    for group, details in local.policies.policies :
    group => {
      name   = "byt-${group}-readonly"
      policy = jsonencode(details.readonly_policy)
    }
    if contains(keys(details), "readonly_policy")
  }

  full_access_permission_sets = {
    for group, details in local.policies.policies :
    group => {
      name   = "byt-${group}-fullAccess"
      policy = jsonencode(details.full_access_policy)
    }
    if contains(keys(details), "full_access_policy")
  }
}

data "aws_organizations_organization" "existing" {}

data "aws_organizations_organizational_units" "existing_ous" {
  parent_id = data.aws_organizations_organization.existing.roots[0].id
}

resource "aws_organizations_organizational_unit" "team" {
  for_each = { for team in var.teams : team => team if length([for ou in data.aws_organizations_organizational_units.existing_ous.children : ou if ou.name == team]) == 0 }

  name      = each.value
  parent_id = data.aws_organizations_organization.existing.roots[0].id

  tags = {
    Name = "BYT-${each.value}"
  }
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each  = local.account_map
  name      = each.value.env
  parent_id = local.created_teams[each.value.team]

  tags = {
    Name = "BYT-${each.value.team}-${each.value.env}"
  }
}

resource "aws_organizations_account" "team_env_account" {
  for_each  = local.account_map
  name      = "BYT-${each.key}"
  email     = local.team_account_emails[each.key]
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  # role_name = "OrganizationAccountAccessRole"
  role_name = "AdministratorAccess"

  tags = {
    Name        = "BYT-${each.key}",
    Team        = each.value.team,
    Environment = each.value.env
  }
}

data "aws_ssoadmin_instances" "main" {}

resource "aws_ssoadmin_permission_set" "readonly_permission_set" {
  for_each     = local.readonly_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  description  = "Read-only access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state  = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_inline_policy" {
  for_each             = aws_ssoadmin_permission_set.readonly_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = each.value.arn
  inline_policy        = local.readonly_permission_sets[each.key].policy
}

resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "PROD"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set["data-eng-PROD"].arn
  principal_id = local.groups["data-eng-PROD"]  # Principal ID of the group
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_permission_set" "full_access_permission_set" {
  for_each     = local.full_access_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  description  = "Full access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state  = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "full_access_inline_policy" {
  for_each             = aws_ssoadmin_permission_set.full_access_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = each.value.arn
  inline_policy        = local.full_access_permission_sets[each.key].policy
}

resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "DEV"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set["data-eng-DEV"].arn
  principal_id = local.groups["data-eng-DEV"]  # Principal ID of the group
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}
