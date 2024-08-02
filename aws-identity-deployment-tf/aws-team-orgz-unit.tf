module "aws-team-organization" {
  source              = "./aws-identity-setup-tf/aws-orgz-team-unit"
  teams               = var.teams 
  workspace           = var.workspace

  providers = {
    aws = aws.aws-us-east-1
  }
}
