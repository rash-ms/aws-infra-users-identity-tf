# Data Infra MakeFile

# <Special Targets>
# Reference: https://www.gnu.org/software/make/manual/html_node/Special-Targets.html
.EXPORT_ALL_VARIABLES:
.ONESHELL:
# </Special Targets>

python_exec=$(shell command -v python3)
# <Recipes>

TERRAFORM_DIR = ./aws-identity-deployment-tf

auth:
		saml2aws login

set_env:
		@echo execute eval $(saml2aws script)

init:
		cd $(TERRAFORM_DIR) && terraform init -upgrade
		
plan:
		cd $(TERRAFORM_DIR) && terraform plan

apply:
		cd $(TERRAFORM_DIR) && terraform apply -auto-approve

init_remove:
		cd $(TERRAFORM_DIR) && rm -rf ./.terraform

destroy:
		cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

init_remove:
		cd $(TERRAFORM_DIR) && rm -dfr ./.terraform

destroy:
		cd $(TERRAFORM_DIR) && terraform destroy

tf_lint_with_write:		
		terraform fmt -recursive -diff=true -write=true ./aws-identity-setup-tf

tf_lint_without_write:
		terraform fmt -recursive -diff=true -write=false ./aws-identity-setup-tf

install_python_deps:
		${python_exec} -m pip install --upgrade pip
		pip install -r ./scripts/temp_install_scripts/requirements.txt

