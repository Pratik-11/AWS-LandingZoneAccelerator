.PHONY: help render deploy teardown plan apply init fmt validate check

help: ## show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  Per-layer targets take LAYER=, e.g.  make plan LAYER=05-network"

render: ## regenerate per-layer tfvars + backend files from configs/landing-zone.yaml
	@python3 scripts/render.py

deploy: ## one-shot: render, then apply every layer in order
	@bash scripts/deploy.sh

teardown: ## destroy every layer in reverse order (asks for confirmation)
	@bash scripts/teardown.sh

init: render ## terraform init one layer
	@test -n "$(LAYER)" || { echo "usage: make init LAYER=<layer>"; exit 1; }
	terraform -chdir=layers/$(LAYER) init -reconfigure -backend-config=backend.s3.tfbackend

plan: render ## terraform plan one layer
	@test -n "$(LAYER)" || { echo "usage: make plan LAYER=<layer>"; exit 1; }
	terraform -chdir=layers/$(LAYER) plan

apply: render ## terraform apply one layer
	@test -n "$(LAYER)" || { echo "usage: make apply LAYER=<layer>"; exit 1; }
	terraform -chdir=layers/$(LAYER) apply

fmt: ## rewrite all .tf to canonical format
	terraform fmt -recursive

validate: ## fmt check + validate every layer, no AWS credentials needed
	@terraform fmt -check -recursive
	@for d in layers/*/; do \
		echo "--> $$d"; \
		terraform -chdir="$$d" init -backend=false -input=false >/dev/null || exit 1; \
		terraform -chdir="$$d" validate || exit 1; \
	done

check: ## verify the toolchain is present
	@command -v terraform >/dev/null || { echo "missing: terraform"; exit 1; }
	@python3 -c "import yaml" 2>/dev/null || { echo "missing: python3 pyyaml"; exit 1; }
	@echo "terraform $$(terraform version -json | python3 -c 'import json,sys;print(json.load(sys.stdin)["terraform_version"])')"
	@echo "pyyaml    $$(python3 -c 'import yaml;print(yaml.__version__)')"
