# Variables
variable "account_id" {
  description = "The AWS Account ID for the target account"
  type        = string
}

variable "region" {
  description = "The AWS Region for the target account"
  type        = string
}

variable "role_name" {
  description = "The IAM role name for cross-account access"
  type        = string
}

variable "repo_sub" {
  description = "The repository sub used in the IAM role condition"
  type        = string
}