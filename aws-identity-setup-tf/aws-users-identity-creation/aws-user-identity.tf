locals {
  yaml_path_prod = "${path.module}/base_conf/byt-aws-prod.yaml"
  yaml_path_dev  = "${path.module}/base_conf/byt-aws-dev.yaml"

  config_prod = yamldecode(file(local.yaml_path_prod))
  config_dev  = yamldecode(file(local.yaml_path_dev))

  # Flatten the user_groups into a single map
  flattened_user_groups_prod = merge([
    for group_name, users in local.config_prod : {
      for user in users : "${group_name}-${user}" => {
        group = group_name
        user  = user
      }
    }
  ]...)

  flattened_user_groups_dev = merge([
    for group_name, users in local.config_dev : {
      for user in users : "${group_name}-${user}" => {
        group = group_name
        user  = user
      }
    }
  ]...)
}


data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

data "aws_identitystore_user" "sso_users_prod" {
  for_each          = local.flattened_user_groups_prod
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  alternate_identifier {
    external_id {
      issuer = "aws"
      id     = each.value.user
    }
  }
}

data "aws_identitystore_user" "sso_users_dev" {
  for_each          = local.flattened_user_groups_dev
  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]

  alternate_identifier {
    external_id {
      issuer = "aws"
      id     = each.value.user
    }
  }
}

data "aws_ssoadmin_permission_set" "all_prod" {
  for_each     = toset([for group, _ in local.config_prod : group])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.key
}

data "aws_ssoadmin_permission_set" "all_dev" {
  for_each     = toset([for group, _ in local.config_dev : group])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.key
}

resource "aws_ssoadmin_account_assignment" "assignments_prod" {
  for_each = local.flattened_user_groups_prod

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.all_prod[each.value.group].arn
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = data.aws_identitystore_user.sso_users_prod[each.key].id
}

resource "aws_ssoadmin_account_assignment" "assignments_dev" {
  for_each = local.flattened_user_groups_dev

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.all_dev[each.value.group].arn
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = data.aws_identitystore_user.sso_users_dev[each.key].id
}




data "local_file" "users" {
  filename = var.yaml_path
}


locals {
  # config = yamldecode(file(var.yaml_path))
  config = yamldecode(data.local_file.users.content)
  
  # Flatten the user_groups into a single map
  flattened_user_groups = merge([
    for group_name, users in local.config : {
      for user in users : "${group_name}-${user}" => {
        group = group_name
        user  = user
      }
    }
  ]...)
}

data "aws_ssoadmin_instances" "main" {}

data "aws_organizations_organization" "main" {}

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

data "aws_ssoadmin_permission_set" "all" {
  for_each     = toset([for group, _ in local.config : group])
  instance_arn = data.aws_ssoadmin_instances.main.arns[0]
  name         = each.key
}

resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = local.flattened_user_groups

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = data.aws_ssoadmin_permission_set.all[each.value.group].arn
  principal_type     = "USER"
  target_id          = data.aws_organizations_organization.main.id
  target_type        = "AWS_ACCOUNT"

  principal_id = data.aws_identitystore_user.sso_users[each.key].id
}
