# module "aws-sso-admin" {
#   source = "../aws-sso-admin"  
#   # sso_admin_role_tags = {  
#   #   RoleWorkspace-0 = "stg"
#   #   RoleWorkspace-1 = "dev"
#   #   RoleWorkspace-2 = "prod"
#   # }

#   PEOPLE_PROD = var.PEOPLE_PROD
#   PEOPLE_STG  = var.PEOPLE_STG
#   PEOPLE_DEV  = var.PEOPLE_DEV

#   providers = {
#     aws = aws.aws-us-east-1
#   }
# }

