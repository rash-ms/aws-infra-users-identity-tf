data "aws_ssoadmin_instances" "main" {}

locals {
  group_ids = module.aws-team-orgz-unit.team_group_ids
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  users_config = yamldecode(file(var.users_yaml_path))
  groups_config = yamldecode(file(var.groups_yaml_path))

  # Flatten the users and groups into a list of maps
  flattened_user_groups = flatten([
    for group_name, users in local.groups_config.groups : [
      for user in users : {
        group = group_name
        user  = user
      }
    ]
  ])

  users_map = { for user in local.users_config.users : user => user }
}

# Create users
resource "aws_identitystore_user" "users" {
  for_each = local.users_map

  identity_store_id = local.identity_store_id
  user_name         = each.value
  display_name      = each.value
  name {
    family_name = split("@", each.value)[0]
    given_name  = split("@", each.value)[0]
  }
  emails {
    primary = true
    type    = "work"
    value   = each.value
  }
}

# Fetch existing groups
data "aws_identitystore_group" "existing_groups" {
  for_each = toset(keys(local.groups_config.groups))

  identity_store_id = local.identity_store_id
  filter {
    attribute_path   = "DisplayName"
    attribute_value  = each.value
  }
}

# Extract the user ID from the full ID
locals {
  user_ids = { for k, v in aws_identitystore_user.users : k => split("/", v.id)[1] }
}

# Attach users to groups
resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_group in local.flattened_user_groups : "${user_group.group}-${user_group.user}" => user_group
  }

  identity_store_id = local.identity_store_id
  group_id          = local.group_ids[each.value.group]
  # group_id          = module.aws-team-orgz-unit.team_group_ids[each.value.group]
  member_id         = local.user_ids[each.value.user]

  lifecycle {
    ignore_changes = [
      identity_store_id,
      group_id,
      member_id,
    ]
  }
}

# # Attach users to groups
# resource "aws_identitystore_group_membership" "memberships" {
#   for_each = {
#     for user_group in local.flattened_user_groups : "${user_group.group}-${user_group.user}" => user_group
#   }

#   identity_store_id = local.identity_store_id
#   group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
#   member_id         = local.user_ids[each.value.user]

#   lifecycle {
#     ignore_changes = [
#       identity_store_id,
#       group_id,
#       member_id,
#     ]
#   }
# }
