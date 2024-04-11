provider "aws" {
  region = "us-east-1"
}

provider "random" {
}

locals {
  users = merge(merge(jsondecode(var.PEOPLE_PROD), jsondecode(var.PEOPLE_STG)), jsondecode(var.PEOPLE_DEV))
}


# Create IAM users
resource "aws_iam_user" "users" {
  for_each = { for user in local.users.people : user.sso_users[0].username => user.sso_users[0] }
  name     = each.value.username
}

# Create IAM groups
resource "aws_iam_group" "groups" {
  for_each = { for user in local.users.people : user.sso_groups[0].group_name => user.sso_groups[0] }
  name     = each.value.group_name
}

# # Add users to groups
# resource "aws_iam_group_membership" "group_memberships" {
#   for_each = { for user in local.users.people : user.sso_users[0].username => user.sso_users[0] }

#   name  = each.key
#   users = [aws_iam_user.users[each.key].name]
#   group = aws_iam_group.groups[each.value.sso_groups[0].group_name].name
# }

# # Define policies (you may need to adjust this part based on your policy requirements)
# data "aws_iam_policy_document" "administrator_access_policy" {
#   statement {
#     actions   = ["*"]
#     resources = ["*"]
#   }
# }

# data "aws_iam_policy_document" "readonly_access_policy" {
#   statement {
#     actions   = ["s3:Get*", "s3:List*"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "administrator_access" {
#   for_each = { for user in local.users.people : user.sso_users[0].username => user.sso_users[0] }

#   name        = "${each.value.username}-AdministratorAccessPolicy"
#   description = "Allows full access to AWS services and resources for ${each.value.username}."
#   policy      = data.aws_iam_policy_document.administrator_access_policy.json
# }

# resource "aws_iam_policy" "readonly_access" {
#   for_each = { for user in local.users.people : user.sso_users[0].username => user.sso_users[0] }

#   name        = "${each.value.username}-ReadOnlyAccessPolicy"
#   description = "Allows read-only access to AWS S3 for ${each.value.username}."
#   policy      = data.aws_iam_policy_document.readonly_access_policy.json
# }

# # Attach policies to users
# resource "aws_iam_user_policy_attachment" "user_policy_attachments" {
#   for_each = { for user in local.users.people : user.sso_users[0].username => user.sso_users[0] }

#   user       = aws_iam_user.users[each.key].name
#   policy_arn = aws_iam_policy.administrator_access[each.key].arn
# }
