variable "environment" {
  description = "The environment to deploy (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

# variable "iam_users_yaml_path" {
#   description = "Path to IAM users YAML file"
#   type        = string
# }


variable "iam_users_yaml_path" {
  description = "Path to IAM users YAML file"
  type        = string
  # default     = "${path.module}/iam_users.yaml"
  default = "./base_conf/iam_users.yaml"
}
