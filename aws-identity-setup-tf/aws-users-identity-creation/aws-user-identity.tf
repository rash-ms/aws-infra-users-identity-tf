data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  # config            = yamldecode(file("${path.module}/sso-config.yaml"))
  config            = yamldecode(file(var.sso-config_path))

  # Extract users and groups from YAML
  all_users = toset(local.config.users)
  all_groups = local.config.groups

  # Filter groups by environment (e.g., "dev" or "prod")
  filtered_groups = {
    for group_name, users in local.all_groups :
    group_name => users
    if contains(split("-", group_name), var.environment)
  }

  # Get unique users from filtered groups
  filtered_users = distinct(flatten([for users in values(local.filtered_groups) : users]))

}

# ----------------------------
# User Management
# ----------------------------
# resource "aws_identitystore_user" "users" {
#   for_each = local.filtered_users

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

resource "aws_identitystore_user" "users" {
  for_each = toset(local.filtered_users)  # Convert list to set

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
resource "aws_identitystore_group" "groups" {
  for_each = local.filtered_groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = "Managed by Terraform"
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
  group_id          = aws_identitystore_group.groups[each.value.group].id
  member_id         = aws_identitystore_user.users[each.value.user].id
}