.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init: ## Download all required Terraform modules and plugins
	@cd vault; terraform init
	@cd rds; terraform init
	@cd admin; terraform init
	@cd nomad; terraform init

refresh:
	@cd vault; terraform refresh -state=vault.tfstate
	@cd rds; terraform refresh -state=rds.tfstate
	@cd admin; terraform refresh -state=admin.tfstate
	@cd nomad; terraform refresh -state=nomad.tfstate

plan_vault:  ## Terraform plan Vault cluster
	@cd vault; terraform plan -state=vault.tfstate
apply_vault: ## Terraform apply Vault cluster
	@cd vault; terraform apply -state=vault.tfstate
destroy_vault: ## Terraform destroy Vault cluster
	@cd vault; terraform destroy -state=vault.tfstate -force

plan_rds:  ## Terraform plan rds server
	@cd rds; terraform plan -state=rds.tfstate
apply_rds: ## Terraform apply rds server
	@cd rds; terraform apply -state=rds.tfstate
destroy_rds: ## Terraform destroy rds server
	@cd rds; terraform destroy -state=rds.tfstate -force

plan_admin: ## Terraform plan admin node
	@cd admin; terraform plan -state=admin.tfstate
apply_admin: ## Terraform apply admin node
	@cd admin; terraform apply -state=admin.tfstate
destroy_admin: ## Terraform destroy admin node
	@cd admin; terraform destroy -state=admin.tfstate -force

plan_nomad: ## Terraform nomad cluster
	@cd nomad; terraform plan -state=nomad.tfstate
apply_nomad: ## Terraform apply nomad cluster
	@cd nomad; terraform apply -state=nomad.tfstate
destroy_nomad: ## Terraform destroy nomad cluster
	@cd nomad; terraform destroy -state=nomad.tfstate -force

destroy_all: ## Destroy all environments
	@cd rds;   terraform destroy -state=rds.tfstate -force
	@cd admin; terraform destroy -state=admin.tfstate -force
	@cd vault; terraform destroy -state=vault.tfstate -force

apply_all: ## Destroy all environments
	@cd vault; terraform apply -state=vault.tfstate -force
	@cd rds;   terraform apply -state=rds.tfstate -force
	@cd admin; terraform apply -state=admin.tfstate -force
	@cd nomad; terraform apply -state=nomad.tfstate -force

clean: ## cleaning up all artifacts
	@echo "Cleaning up"
	@rm -rf .terraform/ \
	        */.terraform/ \
	        *.tfstate* \
					*/*.tfstate* \
					*.pem \
					*/*.pem
