provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

locals {
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

data "aws_ssoadmin_instances" "main" {}

resource "aws_iam_identity_center_user" "create_users" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }

  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  user_name         = each.key
  display_name      = each.key
  email             = each.key
}

resource "aws_iam_identity_center_group_membership" "add_users_to_group" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }

  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  group_id          = lookup(local.config, each.value.group, null)
  member_id         = aws_iam_identity_center_user.create_users[each.key].id
}

# Debug output to verify the mappings
output "debug_mappings" {
  value = local.flattened_user_groups
}
