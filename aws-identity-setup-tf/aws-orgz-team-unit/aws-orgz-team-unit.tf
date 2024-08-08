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

   reverse_group_mappings = {
    for k, v in local.group_mappings : v.group => k
  }
  # Policy group mapping 
  readonly_groups = {
    for k, v in local.group_mappings : k => v if can(regex(".*-PROD$", k))
  }

  full_access_groups = {
    for k, v in local.group_mappings : k => v if can(regex(".*-DEV$", k))
  }

  readonly_permission_set = {
    name   = "byt-readonly",
    policy = jsonencode(local.aws_policies.readonly_policy)
  }

  full_access_permission_set = {
    name   = "byt-fullAccess",
    policy = jsonencode(local.aws_policies.FullAccess_policy)
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
  email     = local.group_mappings[each.key].email
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "BYT-${each.key}",
    Team        = each.value.team,
    Environment = each.value.env
  }
}


data "aws_ssoadmin_instances" "main" {}

# resource "aws_identitystore_group" "team_group" {
#   for_each = { for k, v in local.group_mappings : v.group => k }
#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   display_name      = each.key
# }

resource "aws_identitystore_group" "team_group" {
  for_each = local.group_mappings
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = each.value.group
}


resource "aws_ssoadmin_permission_set" "readonly_permission_set" {
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = local.readonly_permission_set.name
  description  = "Read-only access for PROD"
  session_duration = "PT1H"
  relay_state  = "https://console.aws.amazon.com/"

  tags = {
    Name = local.readonly_permission_set.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "readonly_inline_policy" {
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = aws_ssoadmin_permission_set.readonly_permission_set.arn
  inline_policy        = local.readonly_permission_set.policy
}


resource "aws_ssoadmin_permission_set" "full_access_permission_set" {
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = local.full_access_permission_set.name
  description  = "Full access for DEV"
  session_duration = "PT1H"
  relay_state  = "https://console.aws.amazon.com/"

  tags = {
    Name = local.full_access_permission_set.name
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "full_access_inline_policy" {
  instance_arn         = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn   = aws_ssoadmin_permission_set.full_access_permission_set.arn
  inline_policy        = local.full_access_permission_set.policy
}


# locals {
#   group_ids = {
#     for group, display_name in local.group_mappings :
#     group => split("/", aws_identitystore_group.team_group[display_name].id)[1]
#   }
# }

locals {
  group_ids = {
    for group_name, original_key in local.reverse_group_mappings :
    group_name => split("/", aws_identitystore_group.team_group[original_key].id)[1]
  }
}

resource "aws_ssoadmin_account_assignment" "readonly_assignment" {
  for_each = { for k, v in local.group_mappings : k => v if length(regexall(".*-PROD$", k)) > 0 }
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.readonly_permission_set.arn
  principal_id       = local.group_ids[each.value.group]
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "full_access_assignment" {
  for_each = { for k, v in local.group_mappings : k => v if length(regexall(".*-DEV$", k)) > 0 }
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.full_access_permission_set.arn
  principal_id       = local.group_ids[each.value.group]
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type        = "AWS_ACCOUNT"
}
