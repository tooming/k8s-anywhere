# k8s-lab control plane. Modular profiles keep a 16 GB Mac within budget.
# `make up` bootstraps everything from scratch (see docs/DR.md). `make help` lists all.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Colima VM sizing (host is 16 GB -> leave ~4 GB for macOS)
COLIMA_CPU  ?= 6
COLIMA_MEM  ?= 12
COLIMA_DISK ?= 60

LIVE     := infra/live/local
REPO_DIR := $(shell pwd)

# DR drill blast radius: cluster | full | machine (see docs/DR.md)
SCOPE ?= full

REQUIRED_TOOLS := colima docker k3d kubectl helm terraform terragrunt kustomize argocd vault yq jq mkcert

##@ General

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: preflight
preflight: ## Check required CLI tools are installed
	@missing=0; for t in $(REQUIRED_TOOLS); do \
		if command -v $$t >/dev/null 2>&1; then printf "  ok    %s\n" "$$t"; \
		else printf "  MISS  %s\n" "$$t"; missing=1; fi; done; \
	if [ $$missing -eq 1 ]; then echo "Some tools missing (vault is optional)."; fi

##@ Full lifecycle

.PHONY: up
up: ## Bootstrap the ENTIRE lab from scratch, in order (see docs/DR.md)
	$(MAKE) colima-up
	$(MAKE) cluster-up
	$(MAKE) argocd
	$(MAKE) gitlab-up
	$(MAKE) gitlab-configure
	$(MAKE) root-app
	$(MAKE) vault-bootstrap
	$(MAKE) garage-bootstrap
	@echo ""
	@echo "✅ lab up. Grafana http://localhost:8080  |  see 'make status' and docs/DR.md"

.PHONY: down
down: ## Stop everything (cluster + GitLab + Colima). Data on PVCs/volumes is kept.
	-cd gitlab && docker compose stop
	-cd $(LIVE)/cluster && terragrunt destroy -auto-approve
	-colima stop

##@ Runtime (Colima)

.PHONY: colima-up
colima-up: ## Start the Colima VM (docker runtime) + raise inotify limits
	colima status >/dev/null 2>&1 || colima start --cpu $(COLIMA_CPU) --memory $(COLIMA_MEM) --disk $(COLIMA_DISK) --vm-type vz --mount-type virtiofs
	@colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=1048576 >/dev/null 2>&1 || true

.PHONY: colima-down
colima-down: ## Stop the Colima VM
	colima stop

.PHONY: colima-status
colima-status: ## Show Colima VM status
	colima status

##@ Cluster (k3d via Terraform/Terragrunt)

.PHONY: cluster-up
cluster-up: ## Create the k3d cluster
	cd $(LIVE)/cluster && terragrunt apply -auto-approve

.PHONY: cluster-down
cluster-down: ## Destroy the k3d cluster
	cd $(LIVE)/cluster && terragrunt destroy -auto-approve

##@ Bootstrap (day-0, imperative seam)

.PHONY: argocd
argocd: ## Install ArgoCD (Helm via Terraform)
	cd $(LIVE)/argocd && terragrunt apply -auto-approve

.PHONY: gitlab-up
gitlab-up: ## Start GitLab omnibus and wait until healthy (first boot ~5 min)
	cd gitlab && docker compose up -d
	@echo "waiting for GitLab to be healthy..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' gitlab 2>/dev/null)" = "healthy" ]; do sleep 10; done
	@echo "GitLab healthy."

.PHONY: gitlab-down
gitlab-down: ## Stop GitLab omnibus (frees ~3 GB; keeps its volumes)
	cd gitlab && docker compose stop

.PHONY: gitlab-configure
gitlab-configure: ## Create the gitops project + ArgoCD repo secret, push the repo
	bash scripts/gitlab-pat.sh >/dev/null
	cd $(LIVE)/gitlab && GITLAB_TOKEN="$$(cat $(REPO_DIR)/gitlab/.gitlab-token)" terragrunt apply -auto-approve
	@PAT="$$(cat gitlab/.gitlab-token)"; git remote remove gitlab 2>/dev/null || true; \
		git remote add gitlab "http://root:$${PAT}@localhost:8929/lab/k8s-lab.git"; \
		git push -u gitlab main

.PHONY: root-app
root-app: ## Plant the ArgoCD app-of-apps (everything else syncs from here)
	kubectl apply -f gitops/bootstrap/root-app.yaml

.PHONY: vault-bootstrap
vault-bootstrap: ## Init/unseal Vault + load secrets + k8s auth (idempotent)
	bash scripts/vault-bootstrap.sh

.PHONY: vault-unseal
vault-unseal: ## Manually unseal Vault from the vault-keys Secret
	kubectl -n vault exec vault-0 -- vault operator unseal "$$(kubectl -n vault get secret vault-keys -o jsonpath='{.data.unseal-key}' | base64 -d)"

.PHONY: garage-bootstrap
garage-bootstrap: ## Assign Garage layout + create key/buckets + push S3 key to Vault (idempotent)
	bash scripts/garage-bootstrap.sh

##@ ArgoCD access

.PHONY: argocd-password
argocd-password: ## Print the ArgoCD initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: argocd-ui
argocd-ui: ## Port-forward ArgoCD UI -> http://localhost:8081 (or use http://argocd.127.0.0.1.nip.io:8080)
	kubectl -n argocd port-forward svc/argocd-server 8081:80

##@ Status / RAM guard

.PHONY: status
status: ## Show VM resources + per-namespace memory + any non-running pods
	@colima status 2>&1 | grep -iE 'arch|cpu|memory|disk' || true
	@echo "--- nodes ---"; kubectl top nodes 2>/dev/null || echo "(metrics not ready)"
	@echo "--- memory by namespace (top pods) ---"; \
		kubectl top pods -A --no-headers 2>/dev/null | awk '{gsub(/Mi/,"",$$4); ns[$$1]+=$$4} END {for (n in ns) printf "  %-24s %5d Mi\n", n, ns[n]}' | sort -k2 -rn
	@echo "--- pods not Running/Completed ---"; \
		kubectl get pods -A --no-headers 2>/dev/null | awk '$$4!="Running" && $$4!="Completed" {print "  "$$1"/"$$2"  "$$4}' || true
	@echo "--- GitLab container ---"; docker ps --filter name=gitlab --format '  {{.Names}}  {{.Status}}' 2>/dev/null || true

##@ Disaster recovery (see docs/DR.md)

.PHONY: dr-test
dr-test: ## DR drill: destroy + rebuild from scratch + verify. SCOPE=cluster|full|machine (default full)
	bash scripts/dr-test.sh $(SCOPE)

.PHONY: dr-verify
dr-verify: ## Assert the lab is healthy end-to-end (real checks, no rebuild)
	bash scripts/dr-verify.sh

.PHONY: dr-destroy
dr-destroy: ## Tear the lab down to a clean slate (the 'disaster' only). SCOPE=cluster|full|machine
	bash scripts/dr-destroy.sh $(SCOPE)

.PHONY: dr-bluegreen
dr-bluegreen: ## Zero-downtime blue/green DR: stand up a green cluster + cut over, prove no outage
	bash scripts/dr-bluegreen.sh

.PHONY: dr-bluegreen-down
dr-bluegreen-down: ## Remove the blue/green apparatus (green cluster + front door); blue is untouched
	bash scripts/bluegreen-down.sh
