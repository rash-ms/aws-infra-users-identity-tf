provider "aws" {
  region = "us-east-1"
}

provider "random" {
}

locals {
  all_people = merge(merge(jsondecode(var.PEOPLE_PROD), jsondecode(var.PEOPLE_STG)), jsondecode(var.PEOPLE_DEV))
}

resource "aws_ssoadmin_instance" "example" {
  for_each = { username, user_detail in local.all_people.people : username => user_detail }

  instance_name = "example_instance_${each.key}"
  tags          = var.sso_admin_role_tags
}

resource "aws_ssoadmin_permission_set" "example" {
  for_each = { username, user_detail in local.all_people.people : username => user_detail }

  name               = "example_permission_set_${each.key}"
  description        = "Example permission set for ${each.key}"
  instance_arn       = aws_ssoadmin_instance.example[each.key].arn
  session_duration   = "PT1H"
}

resource "aws_iam_user" "sso_users" {
  for_each = { username, user_detail in local.all_people.people : username => user_detail }

  name = username  # Set the name attribute to the username
}

resource "aws_iam_user_policy_attachment" "sso_user_policy_attachment" {
  for_each = {
    for username, user_detail in local.all_people.people :
      for group in user_detail.sso_groups :
      "${username}-${group.group_name}" => {
        username = username
        group    = group
      }
  }

  user       = aws_iam_user.sso_users[each.value.username].name
  policy_arn = each.value.group.managed_policy_arn
}

resource "aws_ssoadmin_account_assignment" "user_assignment" {
  for_each = {
    for username, user_detail in local.all_people.people :
      for group in user_detail.sso_groups :
      "${username}-${group.group_name}" => {
        username = username
        group    = group
      }
  }

  instance_arn      = aws_ssoadmin_instance.example[each.value.username].arn
  target_id         = aws_iam_user.sso_users[each.value.username].id
  target_type       = "USER"
  permission_set_arn = aws_ssoadmin_permission_set.example[each.value.username].arn

  principal_id   = aws_iam_user.sso_users[each.value.username].name
  principal_type = "USER"
}


resource "null_resource" "update_user_details" {
  for_each = {
    for username, user_detail in local.all_people.people :
      for group in user_detail.sso_groups :
      "${username}-${group.group_name}" => {
        username = username
        group    = group
      }
  }

  depends_on = [aws_ssoadmin_account_assignment.user_assignment]

  provisioner "local-exec" {
    command = <<-EOT
      jq '.[].is_added = true' ${each.value} > ${each.value}_updated.json
      mv ${each.value}_updated.json ${each.value}
    EOT
  }
}
