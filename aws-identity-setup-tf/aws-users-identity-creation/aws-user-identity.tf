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

# Create a null resource to fetch existing users and handle non-existence gracefully
resource "null_resource" "check_user_existence" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.user => user_map
  }

  provisioner "local-exec" {
    command = "echo User ${each.key} not found"
    when    = "create"
    on_failure = "continue"
  }

  triggers = {
    user = each.key
  }
}

# Create users if they don't exist
resource "aws_identitystore_user" "users" {
  for_each = {
    for user_map in local.flattened_user_groups : user_map.user => user_map
    if !contains(keys(null_resource.check_user_existence), user_map.user)
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
  member_id         = aws_identitystore_user.users[each.value.user].id
}

output "existing_groups" {
  value = { for k, v in data.aws_identitystore_group.existing_groups : k => try(v.id, "Group not found") }
}
