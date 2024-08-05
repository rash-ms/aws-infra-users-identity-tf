output "user_ids" {
  value = [for user in data.aws_identitystore_user.sso_users : user.id]
}

output "user_ids_prod" {
  value = [for user in data.aws_identitystore_user.sso_users_prod : user.id]
}

output "user_ids_dev" {
  value = [for user in data.aws_identitystore_user.sso_users_dev : user.id]
}
