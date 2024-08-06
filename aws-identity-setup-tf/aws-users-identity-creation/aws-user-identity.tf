variable "yaml_path" {
  description = "Path to the YAML configuration file"
  type        = string
}

provider "aws" {
  region = "us-east-1" 
}


data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  config = yamldecode(file(var.yaml_path))

  # Flatten the user_groups into a list of maps, ensuring we handle null values and skip empty entries
  flattened_user_groups = flatten([
    for group_name, users in local.config : [
      for user in coalesce(users, []) : {
        group = group_name
        user  = user
      }
      if users != null
    ]
  ])
}

# Check for existing users
resource "null_resource" "check_existing_users" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.user => user_map.user
  }

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore list-users --identity-store-id ${local.identity_store_id} --filter "UserName eq '${each.key}'" > /dev/null 2>&1
    EOT

  }
}

# Check for existing groups
resource "null_resource" "check_existing_groups" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.group => user_map.group
  }

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore list-groups --identity-store-id ${local.identity_store_id} --filter "DisplayName eq '${each.key}'" > /dev/null 2>&1
    EOT

  }
}

# Create users only if they do not exist
resource "aws_identitystore_user" "users" {
  for_each = {
    for user_map in local.flattened_user_groups : "${user_map.user}" => user_map
    if try(null_resource.check_existing_users[user_map.user].id, null) == null
  }

  identity_store_id = local.identity_store_id
  user_name         = each.value.user
  display_name      = each.value.user
  name {
    family_name = split("@", each.value.user)[0]
    given_name  = split("@", each.value.user)[0]
  }
  emails {
    primary = true
    type    = "work"
    value   = each.value.user
  }
}

# Create groups only if they do not exist
resource "aws_identitystore_group" "groups" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.group => user_map.group
    if try(null_resource.check_existing_groups[user_map.group].id, null) == null
  }

  identity_store_id = local.identity_store_id
  display_name      = each.value
  description       = "Group ${each.value}"
}

# Create group memberships only if both user and group exist
resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_map in local.flattened_user_groups : "${user_map.group}-${user_map.user}" => user_map
    if try(null_resource.check_existing_users[user_map.user].id, null) != null && try(null_resource.check_existing_groups[user_map.group].id, null) != null
  }

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.groups[each.value.group].id
  member_id         = aws_identitystore_user.users[each.value.user].id
}

# resource "aws_identitystore_group" "groups" {
#   for_each = toset([for user_map in local.flattened_user_groups : user_map.group])

#   identity_store_id = local.identity_store_id
#   display_name      = each.key
#   description       = "Group ${each.key}"
# }

# resource "aws_identitystore_group_membership" "memberships" {
#   for_each = {
#     for user_map in local.flattened_user_groups : "${user_map.group}-${user_map.user}" => user_map
#   }

#   identity_store_id = local.identity_store_id
#   group_id          = aws_identitystore_group.groups[each.value.group].id
#   member_id         = aws_identitystore_user.users[each.value.user].id
# }






# data "aws_ssoadmin_instances" "main" {}

# locals {
#   identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

#   config = yamldecode(file(var.yaml_path))

#   # Flatten the user_groups into a list of maps, ensuring we handle null values and skip empty entries
#   flattened_user_groups = flatten([
#     for group_name, users in local.config : [
#       for user in coalesce(users, []) : {
#         group = group_name
#         user  = user
#       }
#       if users != null
#     ]
#   ])
# }

# # Fetch existing users
# data "aws_identitystore_user" "existing_users" {
#   for_each = {
#     for user_map in local.flattened_user_groups : user_map.user => user_map.user
#     if user_map.user != ""
#   }

#   identity_store_id = local.identity_store_id
#   filter {
#     attribute_path   = "UserName"
#     attribute_value  = each.key
#   }
# }

# # Fetch existing groups
# data "aws_identitystore_group" "existing_groups" {
#   for_each = toset([for user_map in local.flattened_user_groups : user_map.group])

#   identity_store_id = local.identity_store_id
#   filter {
#     attribute_path   = "DisplayName"
#     attribute_value  = each.key
#   }
# }

# resource "aws_identitystore_user" "users" {
#   for_each = {
#     for user_map in local.flattened_user_groups : "${user_map.user}" => user_map
#     if length(data.aws_identitystore_user.existing_users[user_map.user].filter) == 0
#   }

#   identity_store_id = local.identity_store_id
#   user_name         = each.value.user
#   display_name      = each.value.user
#   name {
#     family_name = split("@", each.value.user)[0]
#     given_name  = split("@", each.value.user)[0]
#   }
#   emails {
#     primary = true
#     type    = "work"
#     value   = each.value.user
#   }
# }

# resource "aws_identitystore_group" "groups" {
#   for_each = {
#     for user_map in local.flattened_user_groups : user_map.group => user_map.group
#     if length(data.aws_identitystore_group.existing_groups[user_map.group].filter) == 0
#   }

#   identity_store_id = local.identity_store_id
#   display_name      = each.value
#   description       = "Group ${each.value}"
# }

# resource "aws_identitystore_group_membership" "memberships" {
#   for_each = {
#     for user_map in local.flattened_user_groups : "${user_map.group}-${user_map.user}" => user_map
#     if length(data.aws_identitystore_user.existing_users[user_map.user].filter) > 0 && length(data.aws_identitystore_group.existing_groups[user_map.group].filter) > 0
#   }

#   identity_store_id = local.identity_store_id
#   group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
#   member_id         = data.aws_identitystore_user.existing_users[each.value.user].id
# }