locals {
  config = yamldecode(file(var.yaml_path))

  group_to_permission_set = {
    "byt-data-eng-fullAccess" = "byt-data-eng-DEV-fullAccess"
    "byt-data-eng-readonly" = "byt-data-eng-PROD-readonly"
  }

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

data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

# Identity Store Users
data "aws_identitystore_user" "sso_users" {
  for_each          = local.flattened_user_groups
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  alternate_identifier {
    external_id {
      issuer = "aws"
      id     = each.value.user
    }
  }
}

# Permission Sets
data "aws_ssoadmin_permission_set" "all" {
  for_each     = toset([for group, _ in local.config : group])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = local.group_to_permission_set[each.key]
}

resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = local.flattened_user_groups

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.all[each.value.permission_set].arn
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = data.aws_identitystore_user.sso_users[each.key].id
}
