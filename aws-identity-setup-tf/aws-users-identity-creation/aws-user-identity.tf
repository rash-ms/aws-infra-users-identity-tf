# ✅ Get AWS Identity Center Instance
data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  users_config  = yamldecode(file(var.users_yaml_path))
  groups_config = yamldecode(file(var.groups_yaml_path))

  # ✅ Filter groups dynamically based on environment
  filtered_groups = {
    for group_name, users in local.groups_config.groups :
    group_name => users
    if contains(split("-", group_name), var.environment)  # Only groups containing 'dev' or 'prod'
  }

  # ✅ Extract unique users for the selected environment
  filtered_users = distinct(flatten([
    for users in values(local.filtered_groups) : users
  ]))

  users_map = { for user in local.filtered_users : user => user }
}

# ✅ Fetch Existing Users from AWS Identity Store (Handle Missing Users)
data "aws_identitystore_user" "existing_users" {
  for_each = { for user in local.users_map : user => user }

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }

  lifecycle {
    postcondition {
      condition     = try(self.id != "", false)  # Ensures Terraform does not fail if the user is missing
      error_message = "User ${each.value} does not exist in Identity Center."
    }
  }
}

# ✅ Create Users Only If They Do NOT Already Exist
resource "aws_identitystore_user" "users" {
  for_each = { for user in local.users_map : user => user
    if !contains(keys(data.aws_identitystore_user.existing_users), user)  # Skip if user exists
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

# ✅ Extract User IDs for Assignments (Handles Users Created in `dev`)
locals {
  user_ids = merge(
    { for k, v in aws_identitystore_user.users : k => split("/", v.id)[1] },
    { for k, v in data.aws_identitystore_user.existing_users : k => try(split("/", v.id)[1], null) }  # Use try() to prevent errors
  )
}

# ✅ Attach Users to Groups (Filtered for Dev/Prod, Skip If User Doesn't Exist)
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
    if lookup(local.user_ids, user_group.user, null) != null  # Only attach existing users
  }

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = local.user_ids[each.value.user]
}
