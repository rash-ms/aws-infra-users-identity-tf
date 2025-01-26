module "identity" {
  source           = "../../aws-identity-setup-tf/aws-users-identity-creation"
  users_yaml_path  = "../../aws-identity-setup-tf/aws-users-identity-creation/base_conf/users.yaml"
  groups_yaml_path = "../../aws-identity-setup-tf/aws-users-identity-creation/base_conf/groups.yaml"

}