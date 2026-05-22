# k8s-lab control plane.
# Modular profiles keep a 16 GB Mac within budget — see README.md / docs/00-architecture.md

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Colima VM sizing (host is 16 GB → leave ~4 GB for macOS)
COLIMA_CPU  ?= 6
COLIMA_MEM  ?= 12
COLIMA_DISK ?= 60

CLUSTER ?= k8s-lab
LIVE    := infra/live/local

REQUIRED_TOOLS := colima docker k3d kubectl helm terraform terragrunt kustomize argocd vault yq jq mkcert

##@ General

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: preflight
preflight: ## Check required CLI tools are installed
	@missing=0; for t in $(REQUIRED_TOOLS); do \
		if command -v $$t >/dev/null 2>&1; then printf "  ok    %s\n" "$$t"; \
		else printf "  MISS  %s\n" "$$t"; missing=1; fi; done; \
	if [ $$missing -eq 1 ]; then echo "Some tools missing — see above."; exit 1; fi

##@ Runtime (Colima)

.PHONY: colima-up
colima-up: ## Start the Colima VM (docker runtime)
	colima start --cpu $(COLIMA_CPU) --memory $(COLIMA_MEM) --disk $(COLIMA_DISK) --vm-type vz --mount-type virtiofs

.PHONY: colima-down
colima-down: ## Stop the Colima VM
	colima stop

.PHONY: colima-status
colima-status: ## Show Colima VM status + resource usage
	colima status

##@ Cluster (k3d via Terraform/Terragrunt)

.PHONY: cluster-up
cluster-up: ## Create the k3d cluster
	cd $(LIVE)/cluster && terragrunt apply

.PHONY: cluster-down
cluster-down: ## Destroy the k3d cluster
	cd $(LIVE)/cluster && terragrunt destroy

##@ Bootstrap (ArgoCD + GitLab)

.PHONY: bootstrap
bootstrap: ## Install ArgoCD into the cluster (Terraform/Terragrunt)
	cd $(LIVE)/argocd && terragrunt apply

.PHONY: argocd-password
argocd-password: ## Print the ArgoCD initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: argocd-ui
argocd-ui: ## Port-forward ArgoCD UI -> http://localhost:8081 (user: admin)
	@echo "ArgoCD UI -> http://localhost:8081  (user: admin, pw via 'make argocd-password')"
	kubectl -n argocd port-forward svc/argocd-server 8081:80

##@ Profiles (bring up ONE heavy area at a time)

.PHONY: gitlab-up gitlab-down tidb-up tidb-down obs-up obs-down
gitlab-up: ## Start GitLab omnibus container
	@echo "TODO (gitops-backbone phase)"
gitlab-down: ## Stop GitLab omnibus container
	@echo "TODO"
tidb-up: ## Enable the TiDB ArgoCD app
	@echo "TODO (data phase)"
tidb-down: ## Disable the TiDB ArgoCD app
	@echo "TODO"
obs-up: ## Enable the observability ArgoCD app (Mimir+Loki+Grafana)
	@echo "TODO (observability phase)"
obs-down: ## Disable the observability ArgoCD app
	@echo "TODO"

##@ Status

.PHONY: status
status: ## Show VM memory + running pods
	@colima status 2>/dev/null || true
	@echo "--- pods ---"
	@kubectl get pods -A 2>/dev/null || echo "cluster not reachable"
