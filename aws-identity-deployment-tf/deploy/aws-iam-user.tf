module "aws-iam-user" {
  source      = "../../aws-identity-setup-tf/aws-iam-user"
  environment = var.environment
}

variable "environment" {
  description = "Environment to deploy to (dev or prod)"
  type        = string
}
