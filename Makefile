# Data Infra MakeFile

# <Special Targets>
# Reference: https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
.EXPORT_ALL_VARIABLES:
.ONESHELL:
# </Special Targets>

python_exec=$(shell command -v python3)
# <Recipes>

TERRAFORM_DIR = ./aws-identity-deployment-tf
RESOURCE = 'module.prod_users.aws_identitystore_user.users["admin@bagitek.com"]'

auth:
		saml2aws login

# set_env:
# 		@echo execute eval $(saml2aws script)

# init:
# 		cd ./aws-identity-deployment-tf && terraform init -upgrade

# plan:
# 		cd ./aws-identity-deployment-tf && terraform plan

# apply:
# 		cd ./aws-identity-deployment-tf && terraform apply -auto-approve


set_env:
		@echo execute eval $(saml2aws script)

init:
		cd $(TERRAFORM_DIR) && terraform init -upgrade

plan:
		cd $(TERRAFORM_DIR) && terraform plan

apply:
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve

state-rm:
		cd $(TERRAFORM_DIR) && terraform state rm $(RESOURCE)

reapply: state-rm apply

init_remove:
		cd $(TERRAFORM_DIR) && rm -dfr ./.terraform

destroy:
		cd $(TERRAFORM_DIR) && terraform destroy

# init_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform init -upgrade -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

# plan_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform plan -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

# apply_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform apply -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

init_remove:
		cd ./aws-identity-deployment-tf && rm -dfr ./.terraform

destroy:
		cd ./aws-identity-deployment-tf && terraform destroy

tf_lint_with_write:		
		terraform fmt -recursive -diff=true -write=true ./aws-identity-setup-tf

tf_lint_without_write:
		terraform fmt -recursive -diff=true -write=false ./aws-identity-setup-tf

install_python_deps:
		${python_exec} -m pip install --upgrade pip
		pip install -r ./scripts/temp_install_scripts/requirements.txt

