module "prod_users" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/base_conf/byt-aws-prod.yaml"

}

module "dev_users" {
  source    = "../aws-identity-setup-tf/aws-users-identity-creation"
  yaml_path = "${path.module}/base_conf/byt-aws-dev.yaml"

}

