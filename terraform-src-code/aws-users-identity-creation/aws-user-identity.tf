# -----------------------------------------------------
# aws-user-identity.tf
# -----------------------------------------------------

# ------------------------------------
# Step 1: Load YAML Configuration & Filter by Environment
# ------------------------------------
data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  # Load configuration from YAML file
  config = yamldecode(file(var.sso_config_path))

  # Get groups from configuration (defaulting to empty map if not set)
  all_groups = lookup(local.config, "groups", {})

  # Filter groups based on the environment ("dev" or "prod")
  filtered_groups = {
    for group_name, users in local.all_groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }

  # Flatten all users across the filtered groups into a unique set
  filtered_users = toset(distinct(flatten([
    for users in values(local.filtered_groups) : users
  ])))
}

# ------------------------------------
# Step 2: Create Users in Dev Environment Only
# ------------------------------------
resource "aws_identitystore_user" "users" {
  for_each = var.environment == "dev" ? local.filtered_users : toset([])

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
# Step 3: Lookup Existing Users in Prod Environment Only
# ------------------------------------
data "aws_identitystore_user" "existing" {
  for_each = var.environment == "prod" ? local.filtered_users : toset([])

  identity_store_id = local.identity_store_id
  filter {
    attribute_path  = "UserName"
    attribute_value = each.value
  }
}

# ------------------------------------
# Step 4: Merge User IDs from Creation or Lookup
# ------------------------------------
locals {
  user_ids = var.environment == "prod" ? {
    for u in local.filtered_users : u => try(data.aws_identitystore_user.existing[u].user_id, null)
    } : {
    for u in local.filtered_users : u => aws_identitystore_user.users[u].user_id
  }

  # Filter out any null values so we only have valid user IDs
  valid_user_ids = { for u, uid in local.user_ids : u => uid if uid != null }
}

# ------------------------------------
# Step 5: Lookup Existing Groups in the Identity Store
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
# Step 6: Build Valid Group–User Pairs
# ------------------------------------
locals {
  group_user_pairs = flatten([
    for group_name, users in local.filtered_groups : [
      for user in users : {
        group   = group_name
        user    = user
        user_id = lookup(local.valid_user_ids, user, null)
      }
    ]
  ])

  # Only include pairs where the user_id is not null
  valid_group_memberships = {
    for pair in local.group_user_pairs : "${pair.group}-${pair.user}" => pair
    if pair.user_id != null
  }
}

# ------------------------------------
# Step 7: Assign Users to Their Respective Groups
# ------------------------------------
resource "aws_identitystore_group_membership" "memberships" {
  for_each = local.valid_group_memberships

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = each.value.user_id

  depends_on = [
    aws_identitystore_user.users
  ]
}


# # ------------------------------------
# # 🚀 Step 1: Load YAML Configuration
# # ------------------------------------
# data "aws_ssoadmin_instances" "main" {}

# locals {
#   identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

#   # ✅ Load users & groups from YAML (Fixing any issues with parsing)
#   config = yamldecode(file(var.sso_config_path))

#   all_users  = toset(lookup(local.config, "users", [])) # ✅ Ensure it always returns a list
#   all_groups = lookup(local.config, "groups", {})       # ✅ Ensure it always returns a map

#   # ✅ Filter groups & users based on environment
#   filtered_groups = {
#     for group_name, users in local.all_groups :
#     group_name => users
#     if contains(split("-", group_name), var.environment)
#   }

#   filtered_users = toset(distinct(flatten([
#     for users in values(local.filtered_groups) : users
#   ])))
# }

# # ------------------------------------
# # 🚀 Step 2: Create Users in Dev, Fetch in Prod
# # ------------------------------------
# resource "aws_identitystore_user" "users" {
#   for_each = var.environment == "dev" ? local.filtered_users : toset([]) # ✅ Ensures consistent type (empty set)

#   identity_store_id = local.identity_store_id
#   user_name         = each.value
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

# # ------------------------------------
# # Step 3: Fetch Existing Users in Prod
# # ------------------------------------
# data "aws_identitystore_user" "existing" {
#   for_each = var.environment == "prod" ? local.filtered_users : toset([]) # ✅ Ensures consistent type (empty set)

#   identity_store_id = local.identity_store_id
#   filter {
#     attribute_path  = "UserName"
#     attribute_value = each.value
#   }
# }

# # ------------------------------------
# # Step 4: Merge Existing & New User IDs
# # ------------------------------------
# locals {
#   user_ids = merge(
#     { for u in local.filtered_users : u => try(data.aws_identitystore_user.existing[u].user_id, null) if var.environment == "prod" },
#     { for k, v in aws_identitystore_user.users : k => v.user_id if var.environment == "dev" }
#   )
# }

# # ------------------------------------
# # Step 5: Fetch Existing Groups
# # ------------------------------------
# data "aws_identitystore_group" "existing_groups" {
#   for_each = local.filtered_groups

#   identity_store_id = local.identity_store_id
#   filter {
#     attribute_path  = "DisplayName"
#     attribute_value = each.key
#   }
# }

# # ------------------------------------
# # 🚀 Step 6: Assign Users to Groups (Fixing for_each Issue)
# # ------------------------------------
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
#     if can(try(local.user_ids[pair.user], null)) # ✅ FIX: Ensures Terraform doesn't fail during planning
#   }

#   identity_store_id = local.identity_store_id
#   group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
#   member_id         = local.user_ids[each.value.user]

#   depends_on = [aws_identitystore_user.users] # ✅ FIX: Ensure users exist before assigning them to groups
# }
