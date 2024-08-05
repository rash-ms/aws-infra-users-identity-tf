provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

module "prod_users" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/aws-identity-setup-tf/aws-users-identity-creation/base_conf/byt-aws-prod.yaml"
}

module "dev_users" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/aws-identity-setup-tf/aws-users-identity-creation/base_conf/byt-aws-dev.yaml"
}
