# CREATE AWS ORGANIZATION UNIT
locals {
  team_account_emails = jsondecode(file("${path.module}/team_emails.json")).team_account_emails

  policies = jsondecode(file("${path.module}/policies.json"))
  groups = local.policies.groups

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

  readonly_permission_sets = {
    for group, name in local.groups : group => {
      name   = "byt-${group}"
      policy = jsonencode(local.policies.readonly_policy)
    }
  }

  full_access_permission_sets = {
    for group, name in local.groups : group => {
      name   = "byt-${group}-readonly"
      policy = jsonencode(local.policies.full_access_policy)
    }
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
  for_each  = toset(var.teams)
  name      = each.value
  # parent_id = aws_organizations_organization.org.roots[0].id
  parent_id = data.aws_organizations_organization.existing.roots[0].id

  tags = {
    Name = "BDT - ${each.value}"
  }
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each  = local.account_map
  name      = each.value.env
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id

  tags = {
    Name = "BDT - ${each.value.team} - ${each.value.env}"
  }
}

resource "aws_organizations_account" "team_env_account" {
  for_each  = local.account_map
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

data "aws_ssoadmin_instances" "main" {}

# Create permission sets for readonly access
resource "aws_ssoadmin_permission_set" "readonly_permission_set" {
  for_each     = local.readonly_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  description  = "Read-only access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state = "https://console.aws.amazon.com/"

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

resource "aws_ssoadmin_permission_set" "full_access_permission_set" {
  for_each     = local.full_access_permission_sets
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  description  = "Full access to AWS resources for ${each.key}"
  session_duration = "PT1H"
  relay_state = "https://console.aws.amazon.com/"

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

# Assign permission sets to users based on environment
resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "Prod"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set[each.key].arn
  principal_id = local.groups[each.key]  # Principal ID of the user
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "NonProd"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set[each.key].arn
  principal_id = local.groups[each.key]  # Principal ID of the user
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_env_account[each.key].id
  target_type = "AWS_ACCOUNT"
}
