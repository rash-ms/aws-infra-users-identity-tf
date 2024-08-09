provider "aws" {
  region = "us-east-1"  
}

module "identity" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  # users_yaml_path = "${path.module}/users.yaml"
  # groups_yaml_path = "${path.module}/groups.yaml"
  group_ids = module.aws-team-orgz-unit.team_group_ids
  users_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/users.yaml"
  groups_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/groups.yaml"
}


variable "group_ids" {
  type        = map(string)
  description = "Map of group names to their respective group IDs."
}

# output "team_group_ids" {
#   description = "Map of team group names to their respective group IDs."
#   value = { for k, v in aws_identitystore_group.team_group : k => v.group_id }
# }


output "created_users" {
  value = module.identity.created_users
}

output "group_memberships" {
  value = module.identity.group_memberships
}