output "user_ids" {
  value = [for user in data.aws_identitystore_user.sso_users : user.id]
}
