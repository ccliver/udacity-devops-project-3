.DEFAULT_GOAL := help

TERRAFORM_VERSION := 0.12.29
MY_IP := "$(shell curl -s https://ifconfig.me)/32"
DOCKER_OPTIONS := -v ${PWD}/terraform:/work \
-w /work \
-it \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
-e TF_VAR_ssh_allowed_cidr=${MY_IP}

init: ## Initialize the Terraform state:  make init
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} init -upgrade=true

plan: ## Run a Terraform plan:  make plan
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} plan

apply: ## Create resources with Terraform
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} apply -auto-approve

validate: ## Validate Terraform syntax
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} validate

outputs: ## Print Terraform outputs
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} output

adhoc: ## Run an ad hoc Terraform command: COMMAND=version make adhoc
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} ${COMMAND}

destroy: ## Destroy the AWS resources with Terraform: make destroy
	@docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} destroy

build_infrastructure: init apply ## Build the VPC and Jenkins

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
