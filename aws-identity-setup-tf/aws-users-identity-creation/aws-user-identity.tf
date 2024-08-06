# provider "aws" {
#   region = "us-east-1"  # Replace with your desired region
# }

# locals {
#   config = yamldecode(file(var.yaml_path))

#   # Flatten the user_groups into a list of maps
#   flattened_user_groups = flatten([
#     for group_name, users in local.config : [
#       for user in users : {
#         group = group_name
#         user  = user
#       }
#     ]
#   ])
# }

# data "aws_ssoadmin_instances" "main" {}

# resource "null_resource" "create_users" {
#   for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }

#   provisioner "local-exec" {
#     command = <<EOT
#       aws identitystore create-user --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --user-name ${each.value.user} --display-name ${each.value.user} --email ${each.value.user}
#     EOT
#   }
# }

# resource "null_resource" "get_user_ids" {
#   for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }
#   depends_on = [null_resource.create_users]

#   provisioner "local-exec" {
#     command = <<EOT
#       user_id=$(aws identitystore list-users --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --query "Users[?UserName=='${each.value.user}'].UserId" --output text)
#       echo ${user_id} > user_id_${each.value.user}.txt
#     EOT
#   }
# }

# data "local_file" "user_ids" {
#   for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }
#   filename = "user_id_${each.key}.txt"
#   depends_on = [null_resource.get_user_ids]
# }

# locals {
#   user_ids = {
#     for user in local.flattened_user_groups : 
#     user.user => chomp(data.local_file.user_ids[user.user].content)
#   }
# }

# resource "null_resource" "add_users_to_group" {
#   for_each = local.user_ids
#   depends_on = [data.local_file.user_ids]

#   provisioner "local-exec" {
#     command = <<EOT
#       aws identitystore create-group-membership --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --group-id ${lookup(local.config, each.value.group, null)} --member-id ${each.value}
#     EOT
#   }
# }

# # Debug output to verify the mappings
# output "debug_mappings" {
#   value = local.flattened_user_groups
# }




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

resource "null_resource" "create_users" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore create-user --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --user-name "${each.value.user}" --display-name "${each.value.user}" --email "${each.value.user}" --first-name "${each.value.user}" --last-name "${each.value.user}"
    EOT
  }
}

resource "null_resource" "get_user_ids" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }
  depends_on = [null_resource.create_users]

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore list-users --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --query "Users[?UserName=='${each.value.user}'].UserId" --output text > user_id_${each.value.user}.txt
    EOT
  }
}

data "local_file" "user_ids" {
  for_each = { for user_map in local.flattened_user_groups : user_map.user => user_map }
  filename = "user_id_${each.key}.txt"
  depends_on = [null_resource.get_user_ids]
}

locals {
  user_ids = {
    for user in local.flattened_user_groups : 
    user.user => chomp(data.local_file.user_ids[user.user].content)
  }
}

resource "null_resource" "add_users_to_group" {
  for_each = local.user_ids
  depends_on = [data.local_file.user_ids]

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore create-group-membership --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --group-id ${lookup(local.config, each.value.group, null)} --member-id ${each.value}
    EOT
  }
}

# Debug output to verify the mappings
output "debug_mappings" {
  value = local.flattened_user_groups
}
