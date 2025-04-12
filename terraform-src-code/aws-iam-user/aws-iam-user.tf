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
