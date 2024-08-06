variable "env" {
  description = "Environment (dev or prod)"
  type        = string
}

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

  # Flatten the user_groups into a list of maps
  flattened_user_groups = flatten([
    for group_name, users in local.config : [
      for user in users : {
        group = group_name
        user  = user
      }
    ]
  ])
}

# Fetch existing users
data "aws_identitystore_user" "existing_users" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.user => user_map.user
  }

  identity_store_id = local.identity_store_id
  filter {
    attribute_path   = "UserName"
    attribute_value  = each.key
  }
}

# Output existing users for debugging
output "existing_users" {
  value = data.aws_identitystore_user.existing_users
}

# Create users if they don't exist
resource "aws_identitystore_user" "users" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.user => user_map
    if length(data.aws_identitystore_user.existing_users[user_map.user].filter) == 0
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

# Fetch existing groups
data "aws_identitystore_group" "existing_groups" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.group => user_map.group
  }

  identity_store_id = local.identity_store_id
  filter {
    attribute_path   = "DisplayName"
    attribute_value  = each.key
  }
}

# Attach users to groups
resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_map in local.flattened_user_groups : "${user_map.group}-${user_map.user}" => user_map
  }

  identity_store_id = local.identity_store_id
  group_id          = data.aws_identitystore_group.existing_groups[each.value.group].id
  member_id         = try(data.aws_identitystore_user.existing_users[each.value.user].id, aws_identitystore_user.users[each.value.user].id)
}
