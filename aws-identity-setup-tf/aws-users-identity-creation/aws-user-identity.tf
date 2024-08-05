locals {
  config  = yamldecode(file(var.yaml_path))
  user_groups = {
    for group_name, users in local.config : group_name => users
  }
}


data "aws_ssoadmin_instances" "main" {}

data "aws_identitystore_user" "sso_users" {
  for_each        = { for user in flatten([for group, users in local.user_groups : users]) : user => user }
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  alternate_identifier {
    external_id {
      issuer = "aws"
      id     = each.key
    }
  }
}

data "aws_ssoadmin_permission_set" "all" {
  for_each     = toset(keys(local.user_groups))
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.key
}

resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = { for group, users in local.user_groups : group => users }

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.all[each.key].arn
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = data.aws_identitystore_user.sso_users[each.value].id
}