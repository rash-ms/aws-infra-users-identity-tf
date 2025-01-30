variable "users_yaml_path" {
  description = "Path to the users YAML configuration file"
  type        = string
  default     = "./base_conf/users.yaml"
}

variable "groups_yaml_path" {
  description = "Path to the groups YAML configuration file"
  type        = string
  default     = "./base_conf/groups.yaml"
}

variable "environment" {
  description = "Environment to provision resources for (e.g., dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}
