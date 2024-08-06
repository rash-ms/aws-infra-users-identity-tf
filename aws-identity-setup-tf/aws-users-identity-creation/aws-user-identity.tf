provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

locals {
  config = yamldecode(file(var.yaml_path))

  # Flatten the user_groups into a list of maps
  flattened_user_groups = [
    for group_name, users in local.config : [
      for user in users : {
        group = group_name
        user  = user
      }
    ]
  ]
}

data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

resource "aws_iam_user" "users" {
  for_each = { for user_map in flatten(local.flattened_user_groups) : user_map.user => user_map }

  name = each.key
  path = "/"
}

resource "aws_iam_group_membership" "group_memberships" {
  for_each = { for user_map in flatten(local.flattened_user_groups) : user_map.user => user_map }

  name = "${each.value.group}_membership"
  users = [each.key]
  group = each.value.group
}

output "usernames" {
  value = aws_iam_user.users.*.name
}
