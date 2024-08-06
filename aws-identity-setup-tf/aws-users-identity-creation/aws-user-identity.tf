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

# Check if users already exist
data "aws_identitystore_user" "existing_users" {
  for_each          = { for user_map in local.flattened_user_groups : user_map.user => user_map }
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  filter {
    attribute_path = "UserName"
    attribute_value = each.key
  }
}

# Create users if they do not already exist
resource "null_resource" "create_users" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }

  provisioner "local-exec" {
    command = <<EOT
      if [ -z "${try(data.aws_identitystore_user.existing_users[each.key].user_id, "")}" ]; then
        aws identitystore create-user --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --user-name "${each.value.user}" --display-name "${each.value.user}" --name '{"FamilyName": "default", "GivenName": "${split("@", each.value.user)[0]}"}' --emails '[{"Primary": true, "Type": "work", "Value": "${each.value.user}"}]'
      fi
    EOT
  }
}

# Capture user IDs after creation
data "aws_identitystore_user" "created_users" {
  for_each          = { for user_map in local.flattened_user_groups : user_map.user => user_map }
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  filter {
    attribute_path = "UserName"
    attribute_value = each.key
  }
}

locals {
  user_ids = {
    for user_map in local.flattened_user_groups : 
    user_map.user => try(data.aws_identitystore_user.existing_users[user_map.user].user_id, data.aws_identitystore_user.created_users[user_map.user].user_id)
  }
}

# Add users to groups
resource "null_resource" "add_users_to_group" {
  for_each = { for user, user_id in local.user_ids : user => user_id if user_id != "" }
  depends_on = [null_resource.create_users]

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore create-group-membership --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --group-id ${lookup(local.config, each.value.group, null)} --member-id ${each.value}
    EOT
  }
}

output "user_ids" {
  value = local.user_ids
}

output "debug_mappings" {
  value = local.flattened_user_groups
}
