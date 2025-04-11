locals {
  dev_usernames  = ["byt-test-cicd-iam-user-dev", "byt-test-s3-iam-user-dev"]
  prod_usernames = ["byt-test-cicd-iam-user-prod", "byt-test-s3-iam-user-prod"]
}

resource "aws_iam_user" "dev_users" {
  provider = aws.dev
  for_each = toset(local.dev_usernames)

  name = each.value
}

resource "aws_iam_user" "prod_users" {
  provider = aws.prod
  for_each = toset(local.prod_usernames)

  name = each.value
}
