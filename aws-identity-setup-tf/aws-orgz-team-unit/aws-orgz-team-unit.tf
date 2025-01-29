terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ✅ Check if AWS Organization Exists
data "aws_organizations_organization" "existing" {}

# ✅ Get AWS SSO Instances (Required for Identity Store and Permission Sets)
data "aws_ssoadmin_instances" "main" {}

# ✅ Load JSON Data
locals {
  aws_policies        = jsondecode(file(var.aws_policies_file)).policies
  aws_team_group_info = jsondecode(file(var.team_group_info_file)).team_group_details

  environments = keys(local.aws_policies)

  env_policy_types = {
    for env, policies in local.aws_policies :
    env => keys(policies)
  }

  group_policies = merge([
    for policy_type in local.env_policy_types[var.environment] :
    lookup(local.aws_team_group_info.attach_group_policies, policy_type, {})
  ]...)

  group_mappings = {
    for group_key, policy_name in local.group_policies :
    group_key => {
      policy_name = policy_name,
      email       = lookup(local.aws_team_group_info.emails, group_key, null)
    } if lookup(local.aws_team_group_info.emails, group_key, null) != null
  }

  selected_policies = local.aws_policies[var.environment]

  permission_sets = {
    for policy_key, policy_details in local.selected_policies :
    "${var.environment}-${policy_details.name}" => {
      name   = policy_details.name,
      policy = jsonencode({
        Version   = policy_details.Version,
        Statement = policy_details.Statement
      })
    }
  }
}

# ✅ Create AWS Organization if it doesn't exist
resource "aws_organizations_organization" "org" {
  count = length(data.aws_organizations_organization.existing.id) > 0 ? 0 : 1

  aws_service_access_principals = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
  lifecycle { prevent_destroy = true }
}

# ✅ Extract the AWS Organization Root ID (Handles both existing & new orgs)
locals {
  org_root_id = coalesce(
    length(data.aws_organizations_organization.existing.roots) > 0 ? data.aws_organizations_organization.existing.roots[0].id : "",
    aws_organizations_organization.org[0].roots[0].id
  )
}

# ✅ Create Organizational Unit (OU) for each team dynamically
resource "aws_organizations_organizational_unit" "team_ou" {
  for_each  = toset(var.teams)
  name      = each.key
  parent_id = local.org_root_id
}

# ✅ Create AWS Accounts Dynamically in the Correct OU
resource "aws_organizations_account" "accounts" {
  for_each  = local.group_mappings
  name      = each.key
  email     = each.value.email

  parent_id = lookup(
    aws_organizations_organizational_unit.team_ou,
    replace(replace(each.key, "-dev", ""), "-prod", ""),
    local.org_root_id
  ).id

  role_name = "OrganizationAccountAccessRole"

  lifecycle {
    precondition {
      condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", each.value.email))
      error_message = "Invalid email format for ${each.key}"
    }
  }
}

# ✅ Create Identity Store Groups with Unique Names
resource "aws_identitystore_group" "groups" {
  for_each          = local.group_mappings
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = "${each.key}-${var.environment}-group"
  description       = "Access group for ${each.key} in ${var.environment}"
}

# ✅ Create Permission Sets with Unique Names
resource "aws_ssoadmin_permission_set" "policy_set" {
  for_each         = local.permission_sets
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name             = "${each.value.name}-${var.environment}"
  description      = "Permission set for ${each.value.name} in ${var.environment}"
  session_duration = "PT1H"
}

# ✅ Attach Inline Policies to Permission Sets
resource "aws_ssoadmin_permission_set_inline_policy" "policy_attachment" {
  for_each           = local.permission_sets
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.policy_set[each.key].arn
  inline_policy      = each.value.policy
}

# ✅ Assign Permission Sets to Accounts Dynamically
resource "aws_ssoadmin_account_assignment" "group_assignment" {
  for_each = {
    for key, value in local.group_mappings :
    "${key}-${value.policy_name}-${var.environment}" => value
  }

  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.policy_set["${var.environment}-${each.value.policy_name}"].arn
  principal_id       = aws_identitystore_group.groups[each.key].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.accounts[each.key].id
  target_type        = "AWS_ACCOUNT"
}



