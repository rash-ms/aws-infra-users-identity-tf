resource "aws_iam_openid_connect_provider" "github_oidc" {
    client_id_list  =   ["sts.amazonaws.com"]
    thumbprint_list =   ["1b511abead59c6ce207077c0bf0e0043b1382612"]
    url             =   "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name               = var.github-action-name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.github-action-role-tags
}

resource "aws_iam_role_policy_attachment" "github_actions_admin_access_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "assume_role_policy" {
    statement {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      effect  = "Allow"
      principals {
        type        =  "Federated"
        identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:aud"
        values   = ["sts.amazonaws.com"]
      }
      condition {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = ["repo:rash-ms/*"]

      }
    }
}

variable "github-action-name" {
  description = "The name for the GitHub Actions IAM role"
  type        = string
}

variable "github-action-role-tags" {
  description = "A map of tags to assign to the role"
  type        = map(string)
}