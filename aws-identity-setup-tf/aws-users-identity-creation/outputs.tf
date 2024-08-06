output "users" {
  value = aws_identitystore_user.users
}

output "groups" {
  value = aws_identitystore_group.groups
}

output "memberships" {
  value = aws_identitystore_group_membership.memberships
}
