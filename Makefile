# Data Infra MakeFile

# <Special Targets>
.EXPORT_ALL_VARIABLES:
.ONESHELL:
# </Special Targets>

# Mark targets as phony
.PHONY: init plan apply destroy init_remove auth set_env tf_lint_with_write tf_lint_without_write install_python_deps

# Python executable
python_exec=$(shell command -v python3)

# Base directory for Terraform modules
TERRAFORM_DIR = ./aws-identity-deployment-tf

# Get a list of module subdirectories dynamically
MODULES = $(shell find $(TERRAFORM_DIR) -mindepth 1 -maxdepth 1 -type d || echo "./dummy")

# Debugging target to print modules
debug:
	@echo "Modules: $(MODULES)"
	@$(foreach module, $(MODULES), echo "Found module: $(module)";)

# Terraform Commands for All Modules
# init:
# 	@echo "Initializing Terraform modules..."
# 	@$(foreach module, $(MODULES), \
# 		echo "Running terraform init in $(module)"; \
# 		(cd $(module) && terraform init -upgrade); \
# 	)

# Terraform Commands for All Modules
init:
	@echo "Initializing Terraform modules..."
	@for module in $(MODULES); do \
		echo "Running terraform init in $$module"; \
		cd $$module && terraform init -upgrade || exit 1; \
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
	@$(foreach module, $(MODULES), \
		echo "Running terraform apply in $(module)"; \
		(cd $(module) && terraform apply -auto-approve); \
	)

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
	pip install -r ./scripts/temp_install_scripts/requirements.txt
