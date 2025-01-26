# Base directory for Terraform modules
TERRAFORM_DIR = ./aws-identity-deployment-tf

# Get a list of module subdirectories dynamically
MODULES = $(shell find $(TERRAFORM_DIR) -mindepth 1 -maxdepth 1 -type d)

# Authentication
auth:
	@saml2aws login

set_env:
	@echo "Exporting environment variables"
	@eval $$(saml2aws script)

# Terraform Commands for All Modules
init:
	@$(foreach module, $(MODULES), \
		echo "Initializing $(module)"; \
		(cd $(module) && terraform init -upgrade); \
	)

plan:
	@$(foreach module, $(MODULES), \
		echo "Planning $(module)"; \
		(cd $(module) && terraform plan); \
	)

apply:
	@$(foreach module, $(MODULES), \
		echo "Applying $(module)"; \
		(cd $(module) && terraform apply -auto-approve); \
	)

destroy:
	@$(foreach module, $(MODULES), \
		echo "Destroying $(module)"; \
		(cd $(module) && terraform destroy -auto-approve); \
	)

init_remove:
	@$(foreach module, $(MODULES), \
		echo "Removing .terraform directory from $(module)"; \
		(cd $(module) && rm -rf .terraform); \
	)

# Terraform Linting
tf_lint_with_write:
	terraform fmt -recursive -diff=true -write=true $(TERRAFORM_DIR)

tf_lint_without_write:
	terraform fmt -recursive -diff=true -write=false $(TERRAFORM_DIR)

# Install Python Dependencies
install_python_deps:
	$(shell command -v python3) -m pip install --upgrade pip
	pip install -r ./scripts/temp_install_scripts/requirements.txt
