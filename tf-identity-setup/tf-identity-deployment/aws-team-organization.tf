module "aws-team-organization" {
  source     = "tf-identity-setup/aws-organization-unit/aws-organization-unit.tf"
  role_tags  = var.role_tags

  providers = {
    aws = aws.aws-us-east-1
  }
}