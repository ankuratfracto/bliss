.PHONY: all fmt validate plan apply destroy

all: fmt validate

fmt:
	test -d terraform && terraform -chdir=terraform/envs/management fmt || true
	terraform -chdir=terraform/envs/audit fmt || true
	terraform -chdir=terraform/envs/workloads fmt || true

validate:
	terraform -chdir=terraform/envs/audit validate || true
	terraform -chdir=terraform/envs/workloads validate || true

plan:
	terraform -chdir=terraform/envs/audit plan
	terraform -chdir=terraform/envs/workloads plan

apply:
	terraform -chdir=terraform/envs/audit apply -auto-approve
	terraform -chdir=terraform/envs/workloads apply -auto-approve
