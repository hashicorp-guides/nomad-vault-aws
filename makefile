.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Download all required Terraform modules and plugins
	@cd vault; terraform init
	@cd rds; terraform init
	@cd admin; terraform init
	@cd nomad; terraform init

plan_vault:  ## Terraform plan Vault cluster
	@cd vault; terraform plan
apply_vault: ## Terraform apply Vault cluster
	@cd vault; terraform apply -state=vault.tfstate
destroy_vault: ## Terraform destroy Vault cluster
	@cd vault; terraform destroy -state=vault.tfstate -force

plan_rds:  ## Terraform plan rds server
	@cd rds; terraform plan
apply_rds: ## Terraform apply rds server
	@cd rds; terraform apply -state=rds.tfstate
destroy_rds: ## Terraform destroy rds server
	@cd rds; terraform destroy -state=rds.tfstate -force

plan_admin: ## Terraform plan admin node
	@cd admin; terraform plan
apply_admin: ## Terraform apply admin node
  @cd admin; terraform apply -state=admin.tfstate
destroy_admin: ## Terraform destroy admin node
	@cd admin; terraform destroy -state=admin.tfstate -force

plan_nomad: ## Terraform nomad cluster
	@cd nomad; terraform plan
apply_nomad: ## Terraform apply nomad cluster
	@cd nomad; terraform apply -state=nomad.tfstate
destroy_nomad: ## Terraform destroy nomad cluster
	@cd nomad; terraform destroy -state=nomad.tfstate -force

destroy_all: ## Destroy all environments
	@cd vault; terraform destroy -state=vault.tfstate -force
  @cd rds;   terraform destroy -state=rds.tfstate -force
	@cd admin; terraform destroy -state=admin.tfstate -force
	@cd nomad; terraform destroy -state=nomad.tfstate -force

clean: ## cleaning up all artifacts
	@echo "Cleaning up"
	@rm -rf .terraform/ \
	        */.terraform/ \
	        *.tfstate* \
					*/*.tfstate* \
					*.pem \
					*/*.pem
