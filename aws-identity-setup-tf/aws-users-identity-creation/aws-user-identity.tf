provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

locals {
  config = yamldecode(file(var.yaml_path))

  # Mapping of groups to permission sets - Update this to match your actual AWS SSO permission sets
  group_to_permission_set = {
    "byt-data-eng-fullAccess" = "byt-data-eng-DEV-fullAccess" # Ensure this exists in AWS SSO
    "byt-data-eng-readonly" = "byt-data-eng-PROD-readonly"   # Ensure this exists in AWS SSO
  }

  # Flatten the user_groups into a list of maps
  flattened_user_groups = [
    for group_name, users in local.config : [
      for user in users : {
        group = group_name
        user  = user
        permission_set = lookup(local.group_to_permission_set, group_name, null)
      }
    ]
  ]
}

data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

resource "null_resource" "create_users" {
  for_each = { for user_map in flatten(local.flattened_user_groups) : user_map.user => user_map }

  provisioner "local-exec" {
    command = <<EOT
      aws sso-admin create-user --instance-arn ${data.aws_ssoadmin_instances.main.arns[0]} --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --user-name ${each.value.user} --display-name ${each.value.user} --email ${each.value.user} --first-name ${split("@", each.value.user)[0]} --last-name default
    EOT
  }
}

resource "null_resource" "get_user_ids" {
  for_each = { for user_map in flatten(local.flattened_user_groups) : user_map.user => user_map }
  depends_on = [null_resource.create_users]

  provisioner "local-exec" {
    command = <<EOT
      aws identitystore list-users --identity-store-id ${data.aws_ssoadmin_instances.main.identity_store_ids[0]} --query "Users[?UserName=='${each.value.user}'].UserId" --output text > ${path.module}/user_id_${each.value.user}.txt
    EOT
  }

  provisioner "local-exec" {
    command = "echo user_id_${each.value.user}=$(cat ${path.module}/user_id_${each.value.user}.txt) >> ${path.module}/user_ids.env"
  }
}

resource "local_file" "user_ids_env" {
  content  = file("${path.module}/user_ids.env")
  filename = "${path.module}/user_ids.env"
  depends_on = [null_resource.get_user_ids]
}

resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = { for user_map in flatten(local.flattened_user_groups) : user_map.user => user_map }
  depends_on = [local_file.user_ids_env]

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = try(data.aws_ssoadmin_permission_set.all[each.value.permission_set].arn, "")
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = chomp(element(split("=", file("${path.module}/user_id_${each.value.user}.txt")), 1))
}

# Permission Sets
data "aws_ssoadmin_permission_set" "all" {
  for_each     = toset([for group_name, users in local.config : lookup(local.group_to_permission_set, group_name, null)])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.key
}

# Debug output to verify the permission sets
output "debug_permission_sets" {
  value = {
    for group_name, users in local.config :
    group_name => lookup(local.group_to_permission_set, group_name, null)
  }
}
