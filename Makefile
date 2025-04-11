# Data Infra MakeFile

# <Special Targets>
.EXPORT_ALL_VARIABLES:
.ONESHELL:
# </Special Targets>

# Mark targets as phony
.PHONY: init plan apply destroy init_remove auth set_env tf_lint_with_write tf_lint_without_write install_python_deps

# Python executable
python_exec=$(shell command -v python3)


TERRAFORM_DIR = ./terraform-src-code

MODULES = $(shell find $(TERRAFORM_DIR) -mindepth 1 -maxdepth 1 -type d)

auth:
		saml2aws login

set_env:
		@echo execute eval $(saml2aws script)

# Debugging target to print modules
debug:
	@echo "Modules: $(MODULES)"
	@$(foreach module, $(MODULES), echo "Found module: $(module)";)
	@echo "Environment detected: $(TF_VAR_environment)"

# Terraform Commands for All Modules
init:
	@echo "Initializing Terraform modules..."
	@for module in $(MODULES); do \
		echo "Processing module: $$module"; \
		module_name=$$(basename $$module); \
			echo "Running terraform init with backend config for $$module_name"; \
			cd $$module && terraform init \
				-backend-config="bucket=byt-infra-user-identity-backend" \
				-backend-config="key=$(TF_VAR_environment)/$$module_name.tfstate" \
				-backend-config="region=us-east-1" || exit 1; \
		cd - > /dev/null; \
	done

plan:
	@echo "Planning Terraform modules..."
	@$(foreach module, $(MODULES), \
		echo "Running terraform plan in $(module)"; \
		(cd $(module) && terraform plan); \
	)

apply:
	@echo "Applying Terraform modules..."
	@for module in $(MODULES); do \
		echo "Running terraform apply in $$module"; \
		if [ "$$module" = "./terraform-src-code/aws-users-identity-creation" ]; then \
			echo "Detected user identity module - applying in two steps..."; \
			(cd $$module && terraform apply -auto-approve -var="create_group_memberships=false"); \
			(cd $$module && terraform apply -auto-approve -var="create_group_memberships=true"); \
		else \
			(cd $$module && terraform apply -auto-approve); \
		fi \
	done

destroy:
	@echo "Destroying Terraform modules..."
	@$(foreach module, $(MODULES), \
		echo "Running terraform destroy in $(module)"; \
		(cd $(module) && terraform destroy -auto-approve); \
	)

init_remove:
	@echo "Removing .terraform directories..."
	@$(foreach module, $(MODULES), \
		echo "Removing .terraform in $(module)"; \
		(cd $(module) && rm -rf .terraform); \
	)

# Terraform Linting
tf_lint_with_write:
	terraform fmt -recursive -diff=true -write=true $(TERRAFORM_DIR)

tf_lint_without_write:
	terraform fmt -recursive -diff=true -write=false $(TERRAFORM_DIR)

# Install Python Dependencies
install_python_deps:
	$(python_exec) -m pip install --upgrade pip
	pip install -r ./utils/temp_install/requirements.txt
