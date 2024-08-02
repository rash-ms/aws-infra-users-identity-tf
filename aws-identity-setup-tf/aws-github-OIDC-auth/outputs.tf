output "iam_roles" {
  value = aws_iam_role.roles
}

output "iam_policies" {
  value = {
    readonly = aws_iam_policy.readonly_policy
    full_access = aws_iam_policy.full_access_policy
  }
}