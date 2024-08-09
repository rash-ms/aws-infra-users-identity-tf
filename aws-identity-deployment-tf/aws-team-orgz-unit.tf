module "aws-team-orgz-unit" {
  source              = "../aws-identity-setup-tf/aws-orgz-team-unit"

  identity_store_id = data.aws_ssoadmin_instances.main.identity_store_ids[0]
  teams               = var.teams 
  workspace           = var.workspace

  providers = {
    aws = aws.aws-us-east-1
  }
}


variable "teams" {
  description = "List of teams"
  type        = list(string)
  default     = ["data-org"]
}

variable "workspace" {
  description = "List of workspaces"
  type        = list(string)
  default     = ["PROD", "DEV"]
}

output "team_group_ids" {
  value = {for k, v in aws_identitystore_group.team_group : k => v.group_id}
}