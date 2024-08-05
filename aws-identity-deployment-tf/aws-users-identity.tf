# module "prod_users" {
#   source    = "../aws-identity-setup-tf/aws-users-identity-creation"
# #   yaml_path = "${path.module}/../base_conf/byt-aws-prod.yaml"
#   yaml_path = "${path.module}/aws-users-identity-creation/base_conf/byt-aws-prod.yaml"
# }

# module "dev_users" {
#   source    = "../aws-identity-setup-tf/aws-users-identity-creation"
#   yaml_path = "${path.module}/../base_conf/byt-aws-dev.yaml"
#    yaml_path = "${path.module}/aws-users-identity-creation/base_conf/byt-aws-prod.yaml"
# }

module "prod_users" {
  source    = "./aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/aws-identity-setup-tf/aws-users-identity-creation/base_conf/byt-aws-prod.yaml"
}

module "dev_users" {
  source    = "./aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/aws-identity-setup-tf/aws-users-identity-creation/base_conf/byt-aws-dev.yaml"
}
