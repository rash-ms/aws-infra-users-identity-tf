data "local_file" "iam_users_config" {
  filename = var.iam_users_yaml_path
}

locals {
  iam_user_config = yamldecode(data.local_file.iam_users_config.content)

  selected_usernames = try(
    lookup(local.iam_user_config, var.environment)["users"],
    []
  )
}

resource "aws_iam_user" "dev_users" {
  provider = aws.dev
  count    = var.environment == "dev" ? length(local.selected_usernames) : 0

  name = local.selected_usernames[count.index]
}

resource "aws_iam_user" "prod_users" {
  provider = aws.prod
  count    = var.environment == "prod" ? length(local.selected_usernames) : 0

  name = local.selected_usernames[count.index]
}

output "created_users" {
  value = local.selected_usernames
}



# locals {
#   dev_usernames  = ["byt-test-cicd-iam-user-dev", "byt-test-s3-iam-user-dev"]
#   prod_usernames = ["byt-test-cicd-iam-user-prod", "byt-test-s3-iam-user-prod"]
# }


# resource "aws_iam_user" "dev_users" {
#   provider = aws.dev
#   for_each = toset(local.dev_usernames)

#   name = each.value
# }

# resource "aws_iam_user" "prod_users" {
#   provider = aws.prod
#   for_each = toset(local.prod_usernames)

#   name = each.value
# }

# locals {
#   dev_usernames  = ["byt-test-cicd-iam-user-dev", "byt-test-s3-iam-user-dev"]
#   prod_usernames = ["byt-test-cicd-iam-user-prod", "byt-test-s3-iam-user-prod"]

#   selected_usernames = (
#     var.environment == "dev" ? local.dev_usernames :
#     var.environment == "prod" ? local.prod_usernames :
#     []
#   )
# }

# resource "aws_iam_user" "users" {
#   provider = var.environment == "dev" ? aws.dev : aws.prod
#   for_each = toset(local.selected_usernames)

#   name = each.value
# }