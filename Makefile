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

init_aws_sso_admin:
		cd ./tf-identity-setup/aws-sso-admin && terraform init -upgrade -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

plan_aws_sso_admin:
		cd ./tf-identity-setup/aws-sso-admin && terraform plan -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

apply_aws_sso_admin:
		cd ./tf-identity-setup/aws-sso-admin && terraform apply -var "PEOPLE_DEV=${PEOPLE_DEV}" -var "PEOPLE_STG=${PEOPLE_STG}" -var "PEOPLE_PROD=${PEOPLE_PROD}"

init_remove:
		cd ./tf-identity-setup && rm -dfr ./.terraform

destroy:
	cd ./tf-identity-setup && terraform destroy

tf_lint_with_write_aws_sso:		
		terraform fmt -recursive -diff=true -write=true ./tf-identity-setup/aws-sso-admin

tf_lint_without_write_aws_sso:
		terraform fmt -recursive -diff=true -write=false ./tf-identity-setup/aws-sso-admin

install_python_deps:
	${python_exec} -m pip install --upgrade pip
	pip install -r ./scripts/temp_install_sh/requirements.txt

