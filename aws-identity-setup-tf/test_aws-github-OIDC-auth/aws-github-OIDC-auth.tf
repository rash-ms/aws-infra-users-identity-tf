locals {
  deployments = jsondecode(file("${path.module}/github-deployment.json"))
  
  dynamic_configs_dev = [
    for alias, details in local.deployments["develop-deployment"] : {
      alias           = alias
      role_name       = details.role_name
      policy_arn      = details.policy_arn
    }
  ]
  
  dynamic_configs_prod = [
    for alias, details in local.deployments["main-deployment"] : {
      alias           = alias
      role_name       = details.role_name
      policy_arn      = details.policy_arn
    }
  ]
}

