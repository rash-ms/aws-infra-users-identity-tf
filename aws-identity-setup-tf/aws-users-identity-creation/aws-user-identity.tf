provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

locals {
  config = yamldecode(file(var.yaml_path))

  # Mapping of groups to permission sets
  group_to_permission_set = {
    "byt-data-eng-fullAccess" = "byt-data-eng-DEV-fullAccess"
    "byt-data-eng-readonly" = "byt-data-eng-PROD-readonly"
  }

  # Flatten the user_groups into a single map
  flattened_user_groups = merge([
    for group_name, users in local.config : {
      for user in users : "${group_name}-${user}" => {
        group = group_name
        user  = user
        permission_set = local.group_to_permission_set[group_name]
      }
    }
  ]...)
}

resource "null_resource" "create_users" {
  for_each = local.flattened_user_groups

  provisioner "local-exec" {
    command = <<EOT
      aws sso-admin create-user --instance-arn ${data.aws_ssoadmin_instances.main.arns[0]} --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --user-name ${each.value.user} --display-name ${each.value.user} --email ${each.value.user} --first-name ${split("@", each.value.user)[0]} --last-name default
    EOT
  }
}

data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

# Permission Sets
data "aws_ssoadmin_permission_set" "all" {
  for_each     = toset([for group, _ in local.config : group])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = local.group_to_permission_set[each.key]
}

resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = local.flattened_user_groups

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = try(data.aws_ssoadmin_permission_set.all[each.value.permission_set].arn, "")
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = aws_identitystore_user.sso_users[each.key].id
}




# locals {
#   config = yamldecode(file(var.yaml_path))

#   # Mapping of groups to permission sets
#   group_to_permission_set = {
#     "byt-data-eng-fullAccess" = "byt-data-eng-DEV-fullAccess"
#     "byt-data-eng-readonly" = "byt-data-eng-PROD-readonly"
#   }

#   # Flatten the user_groups into a single map
#   flattened_user_groups = merge([
#     for group_name, users in local.config : {
#       for user in users : "${group_name}-${user}" => {
#         group = group_name
#         user  = user
#         permission_set = local.group_to_permission_set[group_name]
#       }
#     }
#   ]...)
# }

# resource "aws_iam_identity_center_user" "users" {
#   for_each = { for k, v in local.flattened_user_groups : k => v if length(v.user) > 0 }

#   user_name   = each.value.user
#   display_name = each.value.user
#   email       = each.value.user
#   first_name  = split("@", each.value.user)[0]
#   last_name   = "default"
# }

# data "aws_ssoadmin_instances" "main" {}

# data "aws_organizations_organization" "main" {}

# # Permission Sets
# data "aws_ssoadmin_permission_set" "all" {
#   for_each     = toset([for group, _ in local.config : group])
#   instance_arn = data.aws_ssoadmin_instances.main.arns[0]
#   name         = local.group_to_permission_set[each.key]
# }

# resource "aws_ssoadmin_account_assignment" "assignments" {
#   for_each = local.flattened_user_groups

#   instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
#   permission_set_arn = try(data.aws_ssoadmin_permission_set.all[each.value.permission_set].arn, "")
#   principal_type     = "USER"
#   target_id          = data.aws_organizations_organization.main.id
#   target_type        = "AWS_ACCOUNT"

#   principal_id = aws_iam_identity_center_user.users[each.key].id
# }
