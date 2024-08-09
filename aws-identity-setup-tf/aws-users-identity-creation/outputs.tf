output "created_users" {
  value = aws_identitystore_user.users
}

output "group_memberships" {
  value = aws_identitystore_group_membership.memberships
}

output "debug_group_ids" {
  value = var.group_ids
}
