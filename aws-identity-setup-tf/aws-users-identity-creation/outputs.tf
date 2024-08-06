output "existing_users" {
  description = "Existing users in the identity store"
  value       = aws_identitystore_user.users
}

output "existing_groups" {
  description = "Existing groups in the identity store"
  value       = { for k, v in data.aws_identitystore_group.existing_groups : k => try(v.id, "Group not found") }
}
