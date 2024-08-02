data "local_file" "users" {
  filename = var.yaml_file
}

locals {
  users = yamldecode(data.local_file.users.content)
}

data "aws_ssoadmin_instances" "main" {}

data "aws_identity_store" "main" {}

resource "aws_iam_identity_center_group" "groups" {
  for_each = {for group, _ in local.users : group => group}

  instance_arn = data.aws_ssoadmin_instances.main.arn
  display_name = each.key
}

resource "aws_iam_identity_center_user" "users" {
  for_each = {for user in flatten([for group, users in local.users : [
    for user in users : merge(user, {group = group})]]) : user.email => user
    }

  identity_store_id = data.aws_identity_store.main.identity_store_id
  user_name         = each.value.email
  display_name      = each.value.email
  email             = each.value.email
  given_name        = split("@", each.value.email)[0]
  family_name       = "User"
}

resource "aws_iam_identity_center_group_membership" "group_memberships" {
  for_each = {for user in flatten([for group, users in local.users : [
    for user in users : merge(user, {group = group})]]
    ) : "${user.group}-${user.email}" => user
  }

  identity_store_id = data.aws_identity_store.main.identity_store_id
  group_id          = aws_iam_identity_center_group.groups[each.value.group].group_id
  member_id         = aws_iam_identity_center_user.users[each.value.email].user_id
}