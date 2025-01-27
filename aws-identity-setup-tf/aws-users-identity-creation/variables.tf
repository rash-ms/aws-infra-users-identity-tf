# variable "users_yaml_path" {
#   description = "Path to the users YAML configuration file"
#   type        = string
# }

# variable "groups_yaml_path" {
#   description = "Path to the groups YAML configuration file"
#   type        = string
# }



variable "users_yaml_path" {
  description = "Path to the users YAML configuration file"
  type        = string
  default     = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/users.yaml"
}

variable "groups_yaml_path" {
  description = "Path to the groups YAML configuration file"
  type        = string
  default     = "../aws-identity-setup-tf/aws-users-identity-creation/base_conf/groups.yaml"
}
