# Data Infra MakeFile

# <Special Targets>
# Reference: https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
.EXPORT_ALL_VARIABLES:
.ONESHELL:
# </Special Targets>

python_exec=$(shell command -v python3)
# <Recipes>

auth:
		saml2aws login

set_env:
		@echo execute eval $(saml2aws script)

init:
	cd ./tf-identity-setup/tf-identity-deployment && terraform init -upgrade

plan:
	cd ./tf-identity-setup/tf-identity-deployment && terraform plan

apply:
	cd ./tf-identity-setup/tf-identity-deployment && terraform apply -auto-approve


# init_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform init -upgrade -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

# plan_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform plan -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

# apply_aws_sso_admin:
# 		cd ./tf-identity-setup/tf-identity-deployment/aws-sso-admin && terraform apply -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

init_remove:
		cd ./tf-identity-setup/tf-identity-deployment && rm -dfr ./.terraform

destroy:
	cd ./tf-identity-setup/tf-identity-deployment && terraform destroy

tf_lint_with_write:		
		terraform fmt -recursive -diff=true -write=true ./tf-identity-setup

tf_lint_without_write:
		terraform fmt -recursive -diff=true -write=false ./tf-identity-setup

install_python_deps:
	${python_exec} -m pip install --upgrade pip
	pip install -r ./scripts/temp_install_scripts/requirements.txt

