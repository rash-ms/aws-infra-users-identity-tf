variable "env" {
  description = "Environment (dev or prod)"
  type        = string
}

variable "yaml_path" {
  description = "Path to the YAML configuration file"
  type        = string
  default     = "${path.module}/${var.env}.yaml"
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
    for group_name, group_data in local.config : [
      for user in coalesce(group_data.users, []) : {
        group = group_name
        user  = user.email
        create = user.create
      }
      if group_data.users != null
    ]
  ])

  # Ensure unique names by adding environment prefix
  users_with_env = [
    for user_map in local.flattened_user_groups : {
      group = "${var.env}-${user_map.group}"
      user  = user_map.user
      create = user_map.create
    }
  ]
}

# Output the identity store ID for debugging
output "identity_store_id" {
  value = local.identity_store_id
}

resource "aws_identitystore_user" "users" {
  for_each = {
    for user_map in local.users_with_env : user_map.user => user_map
    if user_map.create == true
  }

  identity_store_id = local.identity_store_id
  user_name         = "${var.env}-${each.value.user}"
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
  for_each = {
    for user_map in local.users_with_env : user_map.group => user_map.group
    if anytrue([for user in local.users_with_env : user.group == user_map.group && user.create == true])
  }

  identity_store_id = local.identity_store_id
  display_name      = each.value
  description       = "Group ${each.value}"
}

resource "aws_identitystore_group_membership" "memberships" {
  for_each = {
    for user_map in local.users_with_env : "${user_map.group}-${user_map.user}" => user_map
    if user_map.create == true
  }

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.groups[each.value.group].id
  member_id         = aws_identitystore_user.users[each.value.user].id
}
