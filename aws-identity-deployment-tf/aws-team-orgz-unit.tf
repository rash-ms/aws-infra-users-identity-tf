module "aws-team-orgz-unit" {
  source              = "../aws-identity-setup-tf/aws-orgz-team-unit"

  # teams               = var.teams 
  # workspace           = var.workspace

  # providers = {
  #   aws = aws.aws-us-east-1
  # }
}


# variable "teams" {
#   description = "List of teams"
#   type        = list(string)
#   default     = ["data-org"]
# }

# variable "workspace" {
#   description = "List of workspaces"
#   type        = list(string)
#   default     = ["PROD", "DEV"]
# }