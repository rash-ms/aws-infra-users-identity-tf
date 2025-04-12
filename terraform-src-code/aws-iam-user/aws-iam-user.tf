locals {
  config_path = "./base_conf/${var.environment}.json"
  config      = jsondecode(file(local.config_path))

  selected_usernames = try(local.config["users"], [])
  role_arn           = local.config["role_arn"]
}

provider "aws" {
  alias  = "byt-iam-user"
  region = "us-east-1"

  assume_role {
    role_arn = local.role_arn
  }
}

resource "aws_iam_user" "users" {
  provider = aws.byt-iam-user
  count    = length(local.selected_usernames)

  name = local.selected_usernames[count.index]
}

output "created_users" {
  value = local.selected_usernames
}


# data "local_file" "iam_users_config" {
#   filename = var.iam_users_yaml_path
# }

# locals {
#   iam_user_config = yamldecode(data.local_file.iam_users_config.content)

#   selected_usernames = try(
#     lookup(local.iam_user_config, var.environment)["users"],
#     []
#   )
# }

# resource "aws_iam_user" "dev_users" {
#   provider = aws.dev
#   count    = var.environment == "dev" ? length(local.selected_usernames) : 0

#   name = local.selected_usernames[count.index]
# }

# resource "aws_iam_user" "prod_users" {
#   provider = aws.prod
#   count    = var.environment == "prod" ? length(local.selected_usernames) : 0

#   name = local.selected_usernames[count.index]
# }

# output "created_users" {
#   value = local.selected_usernames
# }
