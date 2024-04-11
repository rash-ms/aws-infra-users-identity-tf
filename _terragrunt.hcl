terraform {
    source = "."
}

inputs = {
    permissions_list = [
        {
            name = "AdministratorAccess"
            description = "AdministratorAccess"
            managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]
            aws_account = ['637423205666']
            sso_group = ['AdministratorGroup']
        },
        {
            name = "ViewOnlyAccess"
            description = "ViewOnlyAccess"
            managed_policies = ["arn:aws:iam::aws:policy/ViewOnlyAccess"]
            aws_account = ["637423205666"]
            sso_group = ["ViewOnlyGroup"]
        },
        {
            name = "ReadOnlyAccess"
            description = "ReadOnlyAccess"
            managed_policies = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
            aws_account = ["637423205666"]
            sso_group = ["ReadOnlyGroup"]
        },
        {
            name = "Billing"
            description = "Billing"
            managed_policies = ["arn:aws:iam::aws:policy/job-function/Billing"]
            aws_account = ["637423205666"]
            sso_group = ["BillingGroup"]  
        }
    ]
}