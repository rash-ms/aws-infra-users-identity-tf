# ✅ Get AWS Identity Center Instance
data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  users_config  = yamldecode(file(var.users_yaml_path))
  groups_config = yamldecode(file(var.groups_yaml_path))

  # ✅ Filter groups dynamically for the selected environment
  filtered_groups = {
    for group_name, users in local.groups_config.groups :
    group_name => users
    if contains(split("-", group_name), var.environment)  # Detects `dev` or `prod`
  }

  # ✅ Flatten users into a list (only for the selected environment)
  filtered_users = distinct(flatten([
    for users in values(local.filtered_groups) : users
  ]))

  users_map = { for user in local.filtered_users : user => user }
}

# ✅ Fetch Existing Users from AWS Identity Store
data "aws_identitystore_user" "existing_users" {
  for_each          = local.users_map
  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }
}

# ✅ Create Users Only If They Do NOT Already Exist
resource "aws_identitystore_user" "users" {
  for_each = { for user in local.users_map : user => user
    if lookup(data.aws_identitystore_user.existing_users, user, null) == null  # Skip if exists
  }

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

# ✅ Fetch Existing Groups (Dynamically Detects New Groups)
data "aws_identitystore_group" "existing_groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.key
  }
}

# ✅ Extract User IDs for Assignments
locals {
  user_ids = { for k, v in aws_identitystore_user.users : k => split("/", v.id)[1] }
}

# ✅ Attach Users to Groups (Filtered for Dev/Prod)
resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_group in flatten([
      for group_name, users in local.filtered_groups : [
        for user in users : {
          group = group_name
          user  = user
        }
      ]
    ]) :
    "${user_group.group}-${user_group.user}" => user_group
    if lookup(data.aws_identitystore_user.existing_users, user_group.user, null) != null  # Only attach existing users
  }

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = data.aws_identitystore_user.existing_users[each.value.user].id
}
