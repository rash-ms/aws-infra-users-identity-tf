# provider "aws" {
#   alias  = "dev"
#   region = "us-east-1"
#   assume_role {
#     role_arn = local.deployments["develop-deployment"].byt_data_eng_dev.assume_role_arn
#   }
# }

# provider "aws" {
#   alias  = "prod"
#   region = "us-east-1"
#   assume_role {
#     role_arn = local.deployments["main-deployment"].byt_data_eng_prod.assume_role_arn
#   }
# }

# providers = {
#   aws = aws
# }
