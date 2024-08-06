variable "yaml_path" {
  description = "Path to the YAML configuration file"
  type        = string
}

provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}


data "aws_ssoadmin_instances" "main" {}

locals {
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  config = yamldecode(file(var.yaml_path))

  # Flatten the user_groups into a list of maps, ensuring we handle null values
  flattened_user_groups = flatten([
    for group_name, users in local.config : [
      for user in coalesce(users, []) : {
        group = group_name
        user  = user
      }
    ]
  ])
}

resource "aws_identitystore_user" "users" {
  for_each = {
    for user_map in local.flattened_user_groups : "${user_map.user}" => user_map
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

resource "aws_identitystore_group" "groups" {
  for_each = distinct([for user_map in local.flattened_user_groups : user_map.group])

  identity_store_id = local.identity_store_id
  display_name      = each.value
  description       = "Group ${each.value}"
}

resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_map in local.flattened_user_groups : "${user_map.group}-${user_map.user}" => user_map
  }

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.groups[each.value.group].id
  member_id         = aws_identitystore_user.users[each.value.user].id
}
