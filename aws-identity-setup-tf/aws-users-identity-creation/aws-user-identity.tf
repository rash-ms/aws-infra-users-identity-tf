# main.tf
data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  
  # Parse YAML config
  config          = yamldecode(file(var.users_yaml_path))
  all_users       = toset(local.config.users)
  groups          = local.config.groups
  
  # Filter groups by environment (e.g., "dev" or "prod")
  filtered_groups = {
    for group_name, users in local.groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }
  
  # Get unique users from filtered groups
  filtered_users = distinct(flatten([for users in values(local.filtered_groups) : users]))
}

# ----------------------------
# User Management
# ----------------------------
# Check existing users (with error suppression)
data "aws_identitystore_user" "existing_users" {
  for_each = toset(local.filtered_users)

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }

  lifecycle {
    postcondition {
      condition     = length(self.id) > 0
      error_message = "User ${each.value} not found. It will be created."
    }
  }
}

# Create missing users
resource "aws_identitystore_user" "new_users" {
  for_each = {
    for user in local.filtered_users :
    user => user
    if !can(data.aws_identitystore_user.existing_users[user].id)
  }

  identity_store_id = local.identity_store_id
  user_name         = each.value
  display_name      = each.value
  name {
    given_name  = split("@", each.value)[0]
    family_name = split("@", each.value)[0]
  }
  emails {
    value   = each.value
    type    = "work"
    primary = true
  }
}

# ----------------------------
# Group Management
# ----------------------------
# Get existing groups
data "aws_identitystore_group" "existing_groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.key
  }
}

# Combine user IDs from existing and new users
locals {
  user_ids = merge(
    { for u in local.filtered_users : u => data.aws_identitystore_user.existing_users[u].id if can(data.aws_identitystore_user.existing_users[u].id) },
    { for k, v in aws_identitystore_user.new_users : k => v.id }
  )
}

# Add users to groups
resource "aws_identitystore_group_membership" "group_memberships" {
  for_each = {
    for pair in flatten([
      for group_name, users in local.filtered_groups : [
        for user in users : {
          group = group_name
          user  = user
        }
      ]
    ]) : "${pair.group}-${pair.user}" => pair
  }

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = local.user_ids[each.value.user]

  # Only create membership if user exists
  depends_on = [aws_identitystore_user.new_users]
}