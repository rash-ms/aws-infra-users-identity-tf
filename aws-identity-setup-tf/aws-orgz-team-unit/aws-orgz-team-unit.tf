locals {
  aws_team_group_info = jsondecode(file("${path.module}/aws_team_group_info.json")).team_group_details
  aws_policies        = jsondecode(file("${path.module}/aws_policies.json")).policies

  emails = local.aws_team_group_info.emails

  group_policies = merge(
    local.aws_team_group_info.attach_group_policies.full-access-policy,
    local.aws_team_group_info.attach_group_policies.readonly-access-policy
  )

  group_mappings = {
    for key, group in local.group_policies :
    key => {
      group = group,
      email = local.emails[key]
    }
  }

  reverse_group_mappings = {
    for k, v in local.group_mappings : v.group => k
  }

  # Dynamically generate permission set based on policies
  flat_policies = flatten([
      for policy_name, policy_details in local.aws_team_group_info.attach_group_policies : [
        for key, value in policy_details : {
          policy_name = policy_name,
          key         = key,
          policy      = local.aws_policies[policy_name]
        }
      ]
    ])

  permission_sets = {
    for policy in local.flat_policies :
    "${policy.policy_name}-${policy.key}" => {
      name   = "byt-${policy.policy_name}",
      policy = jsonencode(policy.policy)
    }
  }

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
  name     = each.key
  parent_id = data.aws_organizations_organization.existing.roots[0].id
  # parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "team_env" {
  for_each  = local.account_map
  name      = each.value.env
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id

  tags = {
    Name = "BYT-${each.value.team}-${each.value.env}"
  }
}

resource "aws_organizations_account" "team_wrkspc_account" {
  for_each  = local.account_map
  name      = "BYT-${each.key}"
  email     = lookup(local.group_mappings, each.key).email
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "BYT-${each.key}",
    Team        = each.value.team,
    Environment = each.value.env
  }
}


data "aws_ssoadmin_instances" "main" {}

resource "aws_identitystore_group" "team_group" {
  for_each = local.group_mappings
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = "${each.value.group}"
}

resource "aws_ssoadmin_permission_set" "policy_permission_set" {
  for_each = local.permission_sets

  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.value.name
  description  = "${each.key} access"
  session_duration = "PT1H"
  relay_state  = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "policy_permission_set" {
  for_each             = aws_ssoadmin_permission_set.policy_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = each.value.arn
  inline_policy        = local.permission_sets[each.key].policy
}


locals {
  group_ids = {
    for group_name, original_key in local.reverse_group_mappings :
    group_name => split("/", aws_identitystore_group.team_group[original_key].id)[1]
  }
}

resource "aws_ssoadmin_account_assignment" "policy_assignment" {
  for_each           = local.group_mappings
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]

  # Reference the permission set ARN using the correct key
  permission_set_arn = aws_ssoadmin_permission_set.policy_permission_set[
    "${lookup({for p in local.flat_policies : p.key => p.policy_name}, each.key)}-${each.key}"
  ].arn

  principal_id       = local.group_ids[each.value.group]
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type        = "AWS_ACCOUNT"
}
