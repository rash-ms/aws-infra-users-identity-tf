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


# ------------------------------------
# 🚀 Step 1: Load Configuration from YAML
# ------------------------------------
data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  # Load users & groups from YAML
  config = yamldecode(file(var.sso-config_path))

  all_users  = toset(local.config.users)
  all_groups = local.config.groups

  # ✅ Filter groups & users based on environment
  filtered_groups = {
    for group_name, users in local.all_groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }

  filtered_users = toset(distinct(flatten([
    for users in values(local.filtered_groups) : users
  ])))
}

# ------------------------------------
# 🚀 Step 2: Create Users in Dev, Fetch in Prod
# ------------------------------------
resource "aws_identitystore_user" "users" {
  for_each = var.environment == "dev" ? local.filtered_users : toset([])  # ✅ Ensures consistent type (empty set)

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

# ------------------------------------
# Step 3: Fetch Existing Users in Prod
# ------------------------------------
data "aws_identitystore_user" "existing" {
  for_each = var.environment == "prod" ? local.filtered_users : toset([])  # ✅ Ensures consistent type (empty set)

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }
}

# ------------------------------------
# Step 4: Merge Existing & New User IDs
# ------------------------------------
locals {
  user_ids = merge(
    { for u in local.filtered_users : u => try(data.aws_identitystore_user.existing[u].user_id, null) if var.environment == "prod" },
    { for k, v in aws_identitystore_user.users : k => v.user_id if var.environment == "dev" }
  )
}

# ------------------------------------
# Step 5: Fetch Existing Groups
# ------------------------------------
data "aws_identitystore_group" "existing_groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.key
  }
}

# ------------------------------------
# 🚀 Step 6: Assign Users to Groups (Fixing for_each Issue)
# ------------------------------------
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
    if can(try(local.user_ids[pair.user], null))  # ✅ FIX: Ensures Terraform doesn't fail during planning
  }

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = local.user_ids[each.value.user]

  depends_on = [aws_identitystore_user.users]  # ✅ FIX: Ensure users exist before assigning them to groups
}
