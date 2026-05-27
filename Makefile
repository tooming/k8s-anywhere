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
GITLAB_REMOTE_URL := http://root@localhost:8929/lab/k8s-lab.git
GITLAB_PUSH_FLAGS ?=

# Terraform state lives in the off-cluster Garage (infra/tfstate). These fixed
# lab-local creds are imported into that Garage by tfstate-bootstrap.sh; the S3
# backend reads them from the env. Garage-format key (GK + 24 hex / 64-hex secret).
export AWS_ACCESS_KEY_ID     ?= GK31c2d4e5f60718293a4b5c6d
export AWS_SECRET_ACCESS_KEY ?= a1b2c3d4e5f60718293a4b5c6d7e8f90112233445566778899aabbccddeeff00

# DR drill blast radius: cluster | full | machine (see docs/DR.md)
SCOPE ?= full

REQUIRED_TOOLS := colima docker k3d kubectl helm terraform terragrunt kustomize argocd vault yq jq mkcert

##@ General

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: readme-check
readme-check: ## Check README.md is in sync with the Makefile + tools (drift detector)
	@bash scripts/readme-check.sh

.PHONY: lab-ui-check
lab-ui-check: ## Check the Grafana "Lab UIs" panel matches the HTTPRoutes in gitops
	@bash scripts/lab-ui-check.sh

##@ Quality gates (clusterless; run on every commit + in CI)

.PHONY: lint
lint: ## shellcheck the scripts + yamllint the manifests/IaC
	@bash scripts/lint.sh

.PHONY: validate
validate: ## Schema-validate gitops manifests (kubeconform) + terraform (fmt/validate/tflint)
	@bash scripts/validate-manifests.sh
	@bash scripts/validate-terraform.sh

.PHONY: test
test: ## Run the bats unit tests (probe math, DR guards, drift detectors)
	@bash scripts/test.sh

.PHONY: ci
ci: ## Run every clusterless gate: lint + validate + test + drift checks
	@bash scripts/lint.sh
	@bash scripts/validate-manifests.sh
	@bash scripts/validate-terraform.sh
	@bash scripts/test.sh
	@bash scripts/readme-check.sh
	@bash scripts/lab-ui-check.sh

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
	$(MAKE) tfstate-up
	$(MAKE) cluster-up
	$(MAKE) argocd
	$(MAKE) gitlab-up
	$(MAKE) gitlab-configure
	$(MAKE) root-app
	$(MAKE) vault-bootstrap
	$(MAKE) garage-bootstrap
	$(MAKE) frontdoor
	@echo ""
	@echo "✅ lab up. UIs via the front door on :8000 — Grafana http://localhost:8000 · ArgoCD http://argocd.127.0.0.1.nip.io:8000 · run 'make creds' for logins, 'make status' for health"

.PHONY: down
down: ## Stop everything (cluster + GitLab + Colima). Data on PVCs/volumes is kept.
	-cd gitlab && docker compose stop
	-cd $(LIVE)/cluster && terragrunt destroy -auto-approve
	-cd infra/tfstate && docker compose stop
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

##@ Terraform state (off-cluster S3)

.PHONY: tfstate-up
tfstate-up: ## Start + bootstrap the off-cluster Garage holding Terraform state (must precede any apply)
	cd infra/tfstate && docker compose up -d
	@echo "waiting for tfstate Garage to be healthy..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' tfstate-garage 2>/dev/null)" = "healthy" ]; do sleep 2; done
	bash scripts/tfstate-bootstrap.sh
	@echo "tfstate Garage ready (S3 http://localhost:3900, bucket tfstate)."

.PHONY: tfstate-down
tfstate-down: ## Stop the off-cluster Terraform-state Garage (keeps its volume/state)
	cd infra/tfstate && docker compose stop

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
	cd $(LIVE)/argocd && ( \
		terragrunt state list 2>/dev/null | grep -qx 'helm_release.argocd' || { \
			helm -n argocd status argocd >/dev/null 2>&1 && terragrunt import helm_release.argocd argocd/argocd >/dev/null || true; \
		}; \
		terragrunt apply -auto-approve \
	)

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
	@PAT="$$(cat $(REPO_DIR)/gitlab/.gitlab-token)"; \
		cd $(LIVE)/gitlab && export GITLAB_TOKEN="$$PAT"; ( \
			terragrunt state list 2>/dev/null | grep -qx 'gitlab_group.lab' || { \
				gid="$$(curl -fsS --header "PRIVATE-TOKEN: $$PAT" "http://localhost:8929/api/v4/groups/lab" 2>/dev/null | jq -r '.id // empty')"; \
				[ -n "$$gid" ] && terragrunt import gitlab_group.lab "$$gid" >/dev/null || true; \
			}; \
			terragrunt state list 2>/dev/null | grep -qx 'gitlab_project.gitops' || { \
				pid="$$(curl -fsS --header "PRIVATE-TOKEN: $$PAT" "http://localhost:8929/api/v4/projects/lab%2Fk8s-lab" 2>/dev/null | jq -r '.id // empty')"; \
				[ -n "$$pid" ] && terragrunt import gitlab_project.gitops "$$pid" >/dev/null || true; \
			}; \
			terragrunt apply -auto-approve \
		)
	@$(MAKE) gitlab-push

.PHONY: gitlab-push
gitlab-push: ## Push main to the local GitLab repo
	@git remote remove gitlab 2>/dev/null || true; \
		git remote add gitlab "$(GITLAB_REMOTE_URL)"; \
		git config credential."http://localhost:8929".helper "$(REPO_DIR)/scripts/gitlab-credential-helper.sh"; \
		git push $(GITLAB_PUSH_FLAGS) -u gitlab main || { \
			rc="$$?"; \
			if [ -z "$(GITLAB_PUSH_FLAGS)" ]; then \
				echo "gitlab push failed. If the local GitLab branch should be overwritten, rerun 'make gitlab-force-push'." >&2; \
			fi; \
			exit "$$rc"; \
		}

.PHONY: gitlab-force-push
gitlab-force-push: ## Force-push main to the local GitLab repo (--force)
	@$(MAKE) gitlab-push GITLAB_PUSH_FLAGS=--force

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

.PHONY: gitlab-tls-bootstrap
gitlab-tls-bootstrap: ## Mint mkcert TLS for the GitLab HTTPS proxy + publish CA to cluster + start proxy (idempotent, ADR-0006)
	bash scripts/gitlab-tls-bootstrap.sh

.PHONY: grafana-gitsync-bootstrap
grafana-gitsync-bootstrap: ## Create the Grafana Git Sync Repository (Pure Git -> GitLab) so dashboards sync as code (idempotent, ADR-0006)
	bash scripts/grafana-gitsync-bootstrap.sh

##@ ArgoCD access

.PHONY: argocd-password
argocd-password: ## Print the ArgoCD initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: creds
creds: ## Print all lab UI logins (reads live secrets; needs the cluster/GitLab up)
	@a=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d); echo "ArgoCD   admin / $${a:-<cluster down>}    http://argocd.127.0.0.1.nip.io:8080"
	@g=$$(kubectl -n observability get secret grafana-admin -o jsonpath='{.data.admin-password}' 2>/dev/null | base64 -d); echo "Grafana  admin / $${g:-<cluster down>}    http://localhost:8080"
	@r=$$(grep -E '^GITLAB_ROOT_PASSWORD=' gitlab/.env 2>/dev/null | cut -d= -f2-); echo "GitLab   root  / $${r:-<gitlab/.env missing>}    http://localhost:8929"
	@t=$$(kubectl -n vault get secret vault-keys -o jsonpath='{.data.root-token}' 2>/dev/null | base64 -d); echo "Vault    token / $${t:-<cluster down>}    http://vault.127.0.0.1.nip.io:8080"

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

.PHONY: dr-bluegreen-promote
dr-bluegreen-promote: ## Complete blue/green: green->FULL + verify + cutover + RETIRE blue (destructive, zero-downtime)
	bash scripts/dr-bluegreen-promote.sh

.PHONY: frontdoor
frontdoor: ## Ensure the stable front door is up on :8000 -> active cluster (canonical lab entry; UIs use :8000)
	bash scripts/frontdoor-ensure.sh

##@ On-demand components (heavy; not auto-synced — bring up manually)

# Drive ArgoCD via kubectl, not the argocd CLI: the CLI needs a logged-in
# server/token (and --core depends on the repo-server pod), neither of which a
# fresh shell has. Patching the Application's `operation` field hands the work to
# the in-cluster controller — the same engine that syncs every auto-synced app.
# $(1) = Application name in the argocd namespace.
define argocd-sync
	kubectl -n argocd patch application $(1) --type merge -p '{"operation":{"initiatedBy":{"username":"make"},"sync":{}}}'
	@echo "$(1): sync triggered (runs async in-cluster) — watch: kubectl -n argocd get app $(1) -w"
endef

# --cascade=background equivalent: add the resources finalizer, then delete the CR.
define argocd-delete
	-kubectl -n argocd patch application $(1) --type merge -p '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]}}'
	kubectl -n argocd delete application $(1) --ignore-not-found
endef

.PHONY: tidb-operator-up
tidb-operator-up: ## Deploy TiDB Operator via ArgoCD manual sync (~256 MB; do after make up)
	$(call argocd-sync,tidb-operator)

.PHONY: tidb-operator-down
tidb-operator-down: ## Remove TiDB Operator (cascade-deletes resources; keeps namespace + CRDs)
	$(call argocd-delete,tidb-operator)

.PHONY: tidb-up
tidb-up: ## Deploy TiDB cluster via ArgoCD manual sync (~1.5 GB; requires tidb-operator-up first)
	$(call argocd-sync,tidb-cluster)

.PHONY: tidb-down
tidb-down: ## Remove TiDB cluster (cascade-deletes pods/PVCs; keeps namespace + CRDs)
	$(call argocd-delete,tidb-cluster)

.PHONY: tidb-demo-up
tidb-demo-up: ## Deploy TiDB demo app via ArgoCD manual sync (run tidb-up first for a live database)
	$(call argocd-sync,tidb-demo)

.PHONY: tidb-demo-down
tidb-demo-down: ## Remove TiDB demo app (cascade-deletes pods/secrets; keeps namespace)
	$(call argocd-delete,tidb-demo)
