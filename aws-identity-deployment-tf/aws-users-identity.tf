provider "aws" {
  region = "us-east-1"  
}

module "identity" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  # users_yaml_path = "${path.module}/users.yaml"
  # groups_yaml_path = "${path.module}/groups.yaml"
  users_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/users.yaml"
  groups_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/groups.yaml"
}


output "created_users" {
  value = module.identity.created_users
}

output "group_memberships" {
  value = module.identity.group_memberships
}