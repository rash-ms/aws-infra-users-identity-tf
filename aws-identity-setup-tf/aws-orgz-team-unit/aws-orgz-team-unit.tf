locals {
  aws_team_group_info = jsondecode(file("${path.module}/aws_team_group_info.json")).team_group_details
  aws_policies        = jsondecode(file("${path.module}/aws_policies.json")).policies

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

  group_mappings = {
    for key, value in local.aws_team_group_info :
    key => {
      group = value.group,
      email = value.email
    }
  }

  policy_group_mapping = merge(
    local.aws_policies.FullAccess_policy.group,
    local.aws_policies.readonly_policy.group
  )

  readonly_permission_sets = {
    for group, group_name in local.aws_policies.readonly_policy.group :
    "${group}-readonly" => {
      name   = "byt-${group}-readonly"
      policy = jsonencode(local.aws_policies.readonly_policy)
    }
  }

  full_access_permission_sets = {
    for group, group_name in local.aws_policies.FullAccess_policy.group :
    "${group}-fullAccess_policy" => {
      name   = "byt-${group}-FullAccess"
      policy = jsonencode(local.aws_policies.FullAccess_policy)
    }
  }

  # group_ids = {
  #   for group, group_name in local.policy_group_mapping :
  #   group => aws_identitystore_group.team_group[group_name].group_id
  # }

  group_ids = {
    for group, group_name in local.policy_group_mapping :
    group => split("/", aws_identitystore_group.team_group[group_name].id)[1]
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
    Name = "byt-${each.value.team}-${each.value.env}"
  }
}

resource "aws_organizations_account" "team_wrkspc_account" {
  for_each  = local.account_map
  name      = "byt-${each.key}"
  email     = local.group_mappings[each.key].email
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "byt-${each.key}",
    Team        = each.value.team,
    Environment = each.value.env
  }
}


data "aws_ssoadmin_instances" "main" {}


# resource "aws_identitystore_group" "team_group" {
#   for_each = local.policy_group_mapping

#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   display_name      = each.value
# }

resource "aws_identitystore_group" "team_group" {
  for_each = { for k, v in local.group_mappings : v.group => k }
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = each.key
}

# resource "aws_identitystore_group" "team_group" {
#   for_each = local.group_mappings
#   identity_store_id  = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   display_name = each.value.group

#   # alternate_identifier {
#   #   unique_attribute {
#   #     attribute_path = "DisplayName"
#   #     attribute_value = each.value.group
#   #   }
#   # }
# }

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

resource "aws_ssoadmin_permission_set_inline_policy" "fullAccess_inline_policy" {
  for_each             = aws_ssoadmin_permission_set.full_access_permission_set
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = each.value.arn
  inline_policy        = local.full_access_permission_sets[each.key].policy
}


# resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
#   for_each = {
#     for k, v in local.account_map : k => v if v.env == "PROD"
#   }
#   instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
#   permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set[each.key].arn
#   principal_id       = split("/", aws_identitystore_group.team_group[local.group_mappings[each.key].group].id)[1]
#   principal_type     = "GROUP"
#   target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
#   target_type        = "AWS_ACCOUNT"
# }

# resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
#   for_each = {
#     for k, v in local.account_map : k => v if v.env == "DEV"
#   }
#   instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
#   permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set[each.key].arn
#   principal_id       = split("/", aws_identitystore_group.team_group[local.group_mappings[each.key].group].id)[1]
#   principal_type     = "GROUP"
#   target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
#   target_type        = "AWS_ACCOUNT"
# }



resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "PROD"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  # permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set[each.key].arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set["${each.key}-readonly"].arn
  principal_id = local.group_ids[each.key]  # Principal ID of the group
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
  for_each = {
    for k, v in local.account_map : k => v if v.env == "DEV"
  }
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  # permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set[each.key].arn
  permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set["${each.key}-fullAccess"].arn
  principal_id = local.group_ids[each.key]  # Principal ID of the group
  principal_type = "GROUP"
  target_id = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type = "AWS_ACCOUNT"
}
