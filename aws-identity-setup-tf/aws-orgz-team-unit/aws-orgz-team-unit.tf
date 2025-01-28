locals {
  aws_policies        = jsondecode(file(var.aws_policies_file)).policies
  aws_team_group_info = jsondecode(file(var.team_group_info_file)).team_group_details

  emails = local.aws_team_group_info.emails

  # Filter policies based on the current environment
  selected_policies = lookup(local.aws_policies, var.environment, {})

  # Map group policies dynamically based on the environment and teams
  group_policies = merge(
    local.aws_team_group_info.attach_group_policies["privilege-access-policy"],
    local.aws_team_group_info.attach_group_policies["readonly-access-policy"]
  )

  group_mappings = {
    for group_name, group in local.group_policies :
    group_name => {
      group = group,
      email = lookup(local.emails, group_name, null)
    }
  }

  permission_sets = {
    for group_name, policy_details in local.selected_policies :
    group_name => {
      name   = policy_details.name,
      policy = jsonencode(policy_details)
    }
  }

  account_map = {
    for team in var.teams :
    "${team}-${var.environment}" => {
      team = team,
      env  = var.environment
    }
  }
}

# Only create the organization once
data "aws_organizations_organization" "existing" {}

# Ensure the AWS Organization exists only once
resource "aws_organizations_organization" "org" {

  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [data.aws_organizations_organization.existing]
}

# Create organizational units for teams
resource "aws_organizations_organizational_unit" "team" {
  for_each  = toset(var.teams)
  name      = each.key
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create organizational units for environments under each team
resource "aws_organizations_organizational_unit" "team_env" {
  for_each  = local.account_map
  name      = each.value.env
  parent_id = aws_organizations_organizational_unit.team[each.value.team].id

  tags = {
    Name = "${each.value.team}-${each.value.env}"
  }
}

# Create AWS accounts under the organizational units
resource "aws_organizations_account" "team_wrkspc_account" {
  for_each  = local.account_map
  name      = "${each.value.team}-${each.value.env}"
  email     = local.group_mappings["${each.value.team}-${each.value.env}"].email
  parent_id = aws_organizations_organizational_unit.team_env[each.key].id
  role_name = "OrganizationAccountAccessRole"

  tags = {
    Name        = "${each.value.team}-${each.value.env}"
    Team        = each.value.team
    Environment = each.value.env
  }
}

# Retrieve the AWS SSO instance
data "aws_ssoadmin_instances" "main" {}

# Create identity store groups dynamically
resource "aws_identitystore_group" "team_group" {
  for_each          = local.group_mappings
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = each.value.group
}

# Create permission sets dynamically for each group
resource "aws_ssoadmin_permission_set" "policy_permission_set" {
  for_each = local.permission_sets

  instance_arn     = data.aws_ssoadmin_instances.main.arns[0]
  name             = each.value.name
  description      = "${each.value.name} permissions for ${var.environment}"
  session_duration = "PT1H"
  relay_state      = "https://console.aws.amazon.com/"

  tags = {
    Name = each.value.name
  }
}

# Attach inline policies to permission sets
resource "aws_ssoadmin_permission_set_inline_policy" "policy_permission_set" {
  for_each           = aws_ssoadmin_permission_set.policy_permission_set
  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = each.value.arn
  inline_policy      = each.value.policy
}

# Assign permission sets to groups dynamically
resource "aws_ssoadmin_account_assignment" "policy_assignment" {
  for_each = local.group_mappings

  instance_arn       = data.aws_ssoadmin_instances.main.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.policy_permission_set[each.key].arn
  principal_id       = aws_identitystore_group.team_group[each.key].id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.team_wrkspc_account[each.key].id
  target_type        = "AWS_ACCOUNT"
}
