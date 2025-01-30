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
# Create all users specified in filtered_users
resource "aws_identitystore_user" "users" {
  for_each = toset(local.filtered_users)

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
# Create groups specified in filtered_groups
resource "aws_identitystore_group" "groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = "Managed by Terraform"
}

# ----------------------------
# Group Membership Management
# ----------------------------
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
  group_id          = aws_identitystore_group.groups[each.value.group].id
  member_id         = aws_identitystore_user.users[each.value.user].id
}