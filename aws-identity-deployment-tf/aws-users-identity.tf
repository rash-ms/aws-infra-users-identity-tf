provider "aws" {
  region = "us-east-1"  
}

variable "users_yaml_path" {
  description = "Path to the users YAML configuration file"
  type        = string
}

variable "groups_yaml_path" {
  description = "Path to the groups YAML configuration file"
  type        = string
}


module "identity" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  # users_yaml_path = "${path.module}/users.yaml"
  # groups_yaml_path = "${path.module}/groups.yaml"
  users_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/users.yaml"
  groups_yaml_path = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/groups.yaml"
}
