output "iam_roles" {
  value = aws_iam_role.roles
}

output "iam_policies" {
  value = aws_iam_role_policy_attachment.policy_attachment
}