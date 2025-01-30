# data "aws_ssoadmin_instances" "main" {}

# locals {
#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
#   config            = yamldecode(file(var.sso-config_path))

#   # Extract users/groups from YAML
#   all_users  = toset(local.config.users)
#   all_groups = local.config.groups

#   # Filter groups by environment (e.g., "dev")
#   filtered_groups = {
#     for group_name, users in local.all_groups :
#     group_name => users
#     if contains(split("-", group_name), var.environment)
#   }

#   filtered_users = distinct(flatten([for users in values(local.filtered_groups) : users]))
# }

# # ----------------------------
# # User Management
# # ----------------------------
# resource "aws_identitystore_user" "users" {
#   for_each = toset(local.filtered_users)

#   identity_store_id = local.identity_store_id
#   user_name         = each.value  # Must match YAML email exactly
#   display_name      = each.value
#   name {
#     given_name  = split("@", each.value)[0]
#     family_name = split("@", each.value)[0]
#   }
#   emails {
#     value   = each.value
#     type    = "work"
#     primary = true
#   }
# }

# # ----------------------------
# # Existing Group Data Sources
# # ----------------------------
# data "aws_identitystore_group" "existing_groups" {
#   for_each = local.filtered_groups

#   identity_store_id = local.identity_store_id
#   filter {
#     attribute_path  = "DisplayName"
#     attribute_value = each.key
#   }
# }

# # ----------------------------
# # Group Memberships (Fixed)
# # ----------------------------
# resource "aws_identitystore_group_membership" "memberships" {
#   for_each = {
#     for pair in flatten([
#       for group_name, users in local.filtered_groups : [
#         for user in users : {
#           group = group_name
#           user  = user
#         }
#       ]
#     ]) : "${pair.group}-${pair.user}" => pair
#   }

#   identity_store_id = local.identity_store_id
#   group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
#   member_id         = aws_identitystore_user.users[each.value.user].user_id  # ← Critical fix
# }


data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  config            = yamldecode(file(var.sso-config_path))

  # Extract users/groups from YAML
  all_users  = toset(local.config.users)
  all_groups = local.config.groups

  # Filter groups by environment
  filtered_groups = {
    for group_name, users in local.all_groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }

  filtered_users = distinct(flatten([for users in values(local.filtered_groups) : users]))
}

# ----------------------------
# Get ALL existing users (single API call)
# ----------------------------
data "aws_identitystore_users" "all_existing" {
  identity_store_id = local.identity_store_id
  
  filter {
    attribute_path  = "UserName"
    attribute_value = "*"  # Wildcard to get all users
  }
}

# Create map of existing users { "email@domain.com" = "user-id" }
locals {
  existing_user_map = {
    for user in data.aws_identitystore_users.all_existing.users :
    user.user_name => user.user_id
  }
}

# ----------------------------
# User Management (only create missing users)
# ----------------------------
resource "aws_identitystore_user" "new_users" {
  for_each = toset([
    for user in local.filtered_users :
    user if !contains(keys(local.existing_user_map), user)
  ])

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
# Existing Groups Data Sources
# ----------------------------
data "aws_identitystore_group" "existing_groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.key
  }
}

# ----------------------------
# Combine all user IDs
# ----------------------------
locals {
  all_user_ids = merge(
    local.existing_user_map,
    { for k, v in aws_identitystore_user.new_users : k => v.user_id }
  )
}

# ----------------------------
# Group Memberships
# ----------------------------
resource "aws_identitystore_group_membership" "memberships" {
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
  member_id         = local.all_user_ids[each.value.user]
}