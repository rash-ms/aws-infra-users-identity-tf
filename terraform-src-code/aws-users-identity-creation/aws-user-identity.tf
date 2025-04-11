data "aws_ssoadmin_instances" "main" {}

# ------------------------------------
# Step 1: Load YAML Configuration & Filter by Environment
# ------------------------------------
locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]

  # Load files
  groups_config = yamldecode(file(var.groups_path))
  users_config  = yamldecode(file(var.users_path))

  # Get groups (return empty map if not set)
  all_groups = lookup(local.groups_config, "groups", {})

  # Get users (return empty list if not set)
  users_name = lookup(local.users_config, "users", [])

  # Filter groups based on the env ("dev" or "prod")
  filtered_groups = {
    for group_name, users in local.all_groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }

  # Flatten all users across the filtered groups
  filtered_users = toset(distinct(
    concat(
      local.users_name,
      flatten([
        for users in values(local.filtered_groups) : users
      ])
    )
  ))
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

  # Get pairs where the user_id is not null
  valid_group_memberships = {
    for pair in local.group_user_pairs : "${pair.group}-${pair.user}" => pair
    if pair.user_id != null
  }
}

# ------------------------------------
# Step 7: Assign Users to Their Respective Groups
# ------------------------------------
resource "aws_identitystore_group_membership" "memberships" {
  count = var.create_group_memberships ? length(keys(local.valid_group_memberships)) : 0

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[values(local.valid_group_memberships)[count.index].group].id
  member_id         = values(local.valid_group_memberships)[count.index].user_id
}
