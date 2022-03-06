help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dev: ## Run against Dev Env
	@terraform init -reconfigure -backend-config=states/dev.tfvars -no-color -backend-config="key=ami/dev/${component}/terraform.tfstate"
	@terraform apply -auto-approve -var-file=env/dev.tfvars -no-color

prod: ## Run against Prod Env
	@terraform init -backend-config=states/prod.tfvars -no-color
	@terraform apply -auto-approve -var-file=env/prod.tfvars -no-color

dev-destroy: ## Destroy against Dev Env
	@terraform init -reconfigure -backend-config=states/dev.tfvars -no-color -backend-config="key=ami/dev/${component}/terraform.tfstate" -force-copy
	@terraform state rm aws_ami_from_instance.ami
	@terraform destroy -auto-approve -var-file=env/dev.tfvars -no-color