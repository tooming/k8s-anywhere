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

.PHONY: roadmap-check
roadmap-check: ## Check ROADMAP.md has no inline planner notes (per-run narrative belongs in docs/backlog/)
	@bash scripts/roadmap-check.sh

.PHONY: securitycontext-tests-check
securitycontext-tests-check: ## Check tests/securitycontext.bats stays frozen (new PSS tests go in securitycontext-<scope>.bats)
	@bash scripts/securitycontext-tests-check.sh

.PHONY: networkpolicy-tests-check
networkpolicy-tests-check: ## Check tests/networkpolicy.bats stays baseline-only (per-namespace tests go in networkpolicy-<scope>.bats)
	@bash scripts/networkpolicy-tests-check.sh

.PHONY: yq-raw-check
yq-raw-check: ## Check bats tests read yq scalars via yqs() (no bare yq calls — variant-quoting guard)
	@bash scripts/yq-raw-check.sh

.PHONY: git-fixture-isolation-check
git-fixture-isolation-check: ## Check git-fixture bats tests unset GIT_* (so make ci survives running from a hook)
	@bash scripts/git-fixture-isolation-check.sh

.PHONY: securitycontext-tests-mark
securitycontext-tests-mark: ## Refresh tests/.securitycontext-titles — run ONLY after an intentional rename/edit of a monolith test
	@grep -oE '^@test "[^"]*"' tests/securitycontext.bats | sort > tests/.securitycontext-titles
	@echo "  ok  tests/.securitycontext-titles refreshed ($$(wc -l < tests/.securitycontext-titles | tr -d ' ') titles)"

.PHONY: routines-check
routines-check: ## Check routines/*.prompt.md match the last apply (catches edits not synced to claude.ai triggers)
	@bash scripts/routines-check.sh

.PHONY: routines-mark-applied
routines-mark-applied: ## Refresh .routines-applied — run ONLY after applying current routines via Claude Code RemoteTrigger
	@bash scripts/routines-mark-applied.sh

.PHONY: routines-author-check
routines-author-check: ## Fail if an executor-authored (auto/*) change edits routine files — the executor can't apply them to the live trigger (drift detector)
	@bash scripts/routines-author-check.sh

.PHONY: helm-chart-pin-check
helm-chart-pin-check: ## Check every Helm-chart Application pins a targetRevision that exists in its repo (network-tolerant drift detector)
	@bash scripts/helm-chart-pin-check.sh

.PHONY: argocd-crd-ssa-check
argocd-crd-ssa-check: ## Check Applications whose chart ships an oversized CRD sync with ServerSideApply=true (network-tolerant drift detector)
	@bash scripts/argocd-crd-ssa-check.sh

.PHONY: rollouts-plugin-list-check
rollouts-plugin-list-check: ## Check Argo Rollouts plugin Helm values are YAML lists, not strings (drift detector)
	@bash scripts/rollouts-plugin-list-check.sh

.PHONY: mimir-readonly-root-check
mimir-readonly-root-check: ## Check every Mimir write path lands on a writable volume, not the read-only root (drift detector)
	@bash scripts/mimir-readonly-root-check.sh

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

.PHONY: prune-branches
prune-branches: ## Show stale PR branches (merged / unrelated history) — PUSH=1 to delete them
	@bash scripts/prune-stale-branches.sh $(if $(PUSH),--push)

.PHONY: rebase-prs
rebase-prs: ## Prune stale branches, then show/rebase the open PR branches (PUSH=1 to also mutate)
	@bash scripts/prune-stale-branches.sh $(if $(PUSH),--push) || echo "  · prune skipped (no branch-delete permission here) — run 'make prune-branches PUSH=1' where deletes are allowed"
	@bash scripts/rebase-open-prs.sh $(if $(PUSH),--push)

.PHONY: ci
ci: ## Run every clusterless gate: lint + validate + test + drift checks
	@bash scripts/lint.sh
	@bash scripts/validate-manifests.sh
	@bash scripts/validate-kustomize.sh
	@bash scripts/validate-terraform.sh
	@bash scripts/test.sh
	@bash scripts/readme-check.sh
	@bash scripts/lab-ui-check.sh
	@bash scripts/roadmap-check.sh
	@bash scripts/securitycontext-tests-check.sh
	@bash scripts/networkpolicy-tests-check.sh
	@bash scripts/yq-raw-check.sh
	@bash scripts/git-fixture-isolation-check.sh
	@bash scripts/routines-check.sh
	@bash scripts/routines-author-check.sh
	@bash scripts/helm-chart-pin-check.sh
	@bash scripts/argocd-crd-ssa-check.sh
	@bash scripts/rollouts-plugin-list-check.sh
	@bash scripts/mimir-readonly-root-check.sh

.PHONY: install-hooks
install-hooks: ## Wire up .githooks/ as the local git hooks directory (run once per clone)
	@git config core.hooksPath .githooks
	@chmod +x .githooks/pre-push .githooks/post-merge
	@echo "  ok  pre-push hook installed (make ci runs before every push)"

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
	$(MAKE) cilium-up
	$(MAKE) coredns-host-alias
	$(MAKE) argocd
	$(MAKE) gitlab-up
	$(MAKE) gitlab-configure
	$(MAKE) root-app
	$(MAKE) vault-bootstrap
	$(MAKE) gitlab-tls-bootstrap
	$(MAKE) garage-bootstrap
	$(MAKE) cosign-bootstrap
	$(MAKE) frontdoor
	$(MAKE) grafana-gitsync-bootstrap
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

.PHONY: coredns-host-alias
coredns-host-alias: ## Teach CoreDNS to resolve host.k3d.internal -> docker gateway (k3d 5.x on Colima omits this)
	@bash scripts/coredns-host-alias.sh

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
	@bash scripts/gitlab-env-ensure.sh
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
			terragrunt state list 2>/dev/null | grep -qx 'gitlab_branch_protection.main' || { \
				pid="$$(curl -fsS --header "PRIVATE-TOKEN: $$PAT" "http://localhost:8929/api/v4/projects/lab%2Fk8s-lab" 2>/dev/null | jq -r '.id // empty')"; \
				[ -n "$$pid" ] && terragrunt import gitlab_branch_protection.main "$${pid}:main" >/dev/null || true; \
			}; \
			terragrunt apply -auto-approve \
		)
	@$(MAKE) gitlab-push

# A from-scratch `make up` hits two GitLab-auth footguns at this step, both fatal
# with the same "HTTP Basic: Access denied" 401:
#   1. Activation race — on a freshly-booted GitLab the git-over-HTTP path
#      (workhorse/gitlab-shell) lags the Rails API in recognizing a brand-new PAT.
#      terragrunt already used the token, but `git push` moments later still 401s.
#      Gate the push on a git-receive-pack probe (curl, bypasses any credential
#      store) until GitLab accepts the token for git.
#   2. Stale cached credential — the host's credential helper (e.g. osxkeychain)
#      persists across GitLab rebuilds and serves a dead token from a previous
#      instance ahead of our helper. Push with an isolated helper list (reset, then
#      only the repo helper that reads gitlab/.gitlab-token) so nothing stale wins.
.PHONY: gitlab-push
gitlab-push: ## Push main to the local GitLab repo
	@git remote remove gitlab 2>/dev/null || true; \
		git remote add gitlab "$(GITLAB_REMOTE_URL)"; \
		pat="$$(cat $(REPO_DIR)/gitlab/.gitlab-token 2>/dev/null)"; \
		printf 'waiting for GitLab to accept the PAT for git push'; \
		for i in $$(seq 1 30); do \
			code="$$(curl -s -o /dev/null -w '%{http_code}' --user "root:$$pat" "http://localhost:8929/lab/k8s-lab.git/info/refs?service=git-receive-pack" 2>/dev/null)"; \
			[ "$$code" = "200" ] && { printf ' ready\n'; break; }; \
			printf '.'; sleep 2; \
		done; \
		git -c credential.helper= -c credential.helper="$(REPO_DIR)/scripts/gitlab-credential-helper.sh" \
			push $(GITLAB_PUSH_FLAGS) -u gitlab main || { \
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

.PHONY: cosign-bootstrap
cosign-bootstrap: ## Generate cosign keypair + seed cosign-public-key ConfigMap in kyverno namespace (idempotent, ADR-0019)
	bash scripts/cosign-bootstrap.sh

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
	@ru=$$(kubectl -n data get secret rabbitmq-creds -o jsonpath='{.data.username}' 2>/dev/null | base64 -d); rp=$$(kubectl -n data get secret rabbitmq-creds -o jsonpath='{.data.password}' 2>/dev/null | base64 -d); echo "RabbitMQ $${ru:-<cluster down>} / $${rp:-<cluster down>}    http://rabbitmq.127.0.0.1.nip.io:8080"
	@dp=$$(kubectl -n data get secret valkey-creds -o jsonpath='{.data.password}' 2>/dev/null | base64 -d); echo "Valkey   (requirepass) / $${dp:-<cluster down>}    valkey://valkey.data.svc:6379"

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

.PHONY: dr-restore
dr-restore: ## Restore every stateful namespace from latest Velero backup (Objective O3)
	@./scripts/dr-restore.sh data tidb capstone vault

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

##@ Capstone (demo + learning path)

.PHONY: capstone-demo
capstone-demo: ## Run the end-to-end capstone demo: ArgoCD health → ExternalSecret → HTTP 200 → Tempo trace (O6, 900 s budget)
	bash scripts/capstone-demo.sh

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

# --- Cilium CNI (always-on once enabled; run before ArgoCD on fresh clusters) ----
# Cilium replaces k3s-bundled Flannel (disable_default_cni=true — ADR-0014).
# Bootstrap order: make cluster-up → make cilium-up → make argocd → rest of make up.
# After the initial install, ArgoCD adopts the Helm release and manages it.
#
# kube-proxy-free (kubeProxyReplacement=true) requires the real kube-apiserver
# host:port: with no kube-proxy, a pod that is NOT co-located with the apiserver
# cannot reach the kubernetes ClusterIP (10.43.0.1) until Cilium itself programs
# it — a chicken-and-egg that leaves the apiserver unreachable. We read the
# endpoint k3d assigned (deterministic only per-run, so derive it, don't hardcode).
.PHONY: cilium-up
cilium-up: ## Install Cilium CNI via Helm — run BEFORE make argocd on fresh clusters (ADR-0014)
	@api_host="$$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}')"; \
	api_port="$$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].ports[0].port}')"; \
	[ -n "$$api_host" ] && [ -n "$$api_port" ] || { echo "cilium-up: could not resolve kube-apiserver endpoint — is the cluster up?" >&2; exit 1; }; \
	echo "[cilium] kube-proxy-free apiserver endpoint: k8sServiceHost=$$api_host k8sServicePort=$$api_port"; \
	helm upgrade --install cilium cilium \
		--repo https://helm.cilium.io \
		--version 1.16.6 \
		--namespace kube-system \
		--create-namespace \
		--set kubeProxyReplacement=true \
		--set k8sServiceHost=$$api_host \
		--set k8sServicePort=$$api_port \
		--set hubble.enabled=false \
		--set operator.replicas=1 \
		--wait --timeout 5m
	@echo "Cilium CNI installed — pod networking active. Continue with: make argocd"

.PHONY: cilium-down
cilium-down: ## Remove Cilium CNI — WARNING: drops all pod networking; only during cluster teardown
	helm uninstall cilium --namespace kube-system --ignore-not-found

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

.PHONY: artifactory-up
artifactory-up: ## Deploy Artifactory OSS via ArgoCD manual sync (~1-2 GB JVM; do after make up)
	$(call argocd-sync,artifactory)
	$(call argocd-sync,artifactory-extras)

.PHONY: artifactory-down
artifactory-down: ## Remove Artifactory OSS and its Envoy route (reclaims ~1-2 GB RAM)
	$(call argocd-delete,artifactory-extras)
	$(call argocd-delete,artifactory)

.PHONY: istio-up
istio-up: ## Deploy Istio ambient mesh via ArgoCD manual sync (~480 MB; do after make up)
	$(call argocd-sync,istio-base)
	$(call argocd-sync,istio-cni)
	$(call argocd-sync,istiod)
	$(call argocd-sync,ztunnel)

.PHONY: istio-down
istio-down: ## Remove Istio ambient mesh: ztunnel → istiod → cni → base (reclaims ~480 MB)
	$(call argocd-delete,ztunnel)
	$(call argocd-delete,istiod)
	$(call argocd-delete,istio-cni)
	$(call argocd-delete,istio-base)

.PHONY: kiali-up
kiali-up: ## Deploy Kiali service mesh UI via ArgoCD manual sync (~200 MB; requires istio-up first)
	$(call argocd-sync,kiali)
	$(call argocd-sync,kiali-extras)

.PHONY: kiali-down
kiali-down: ## Remove Kiali and its Envoy route (reclaims ~200 MB)
	$(call argocd-delete,kiali-extras)
	$(call argocd-delete,kiali)

.PHONY: mesh-up
mesh-up: istio-up kiali-up ## Deploy Istio ambient mesh + Kiali together (istio-up then kiali-up)

.PHONY: mesh-down
mesh-down: kiali-down istio-down ## Remove Kiali then Istio ambient mesh (kiali-down then istio-down)

.PHONY: longhorn-up
longhorn-up: ## Deploy Longhorn distributed block storage via ArgoCD manual sync (~350-400 MB; do after make up)
	$(call argocd-sync,longhorn)
	$(call argocd-sync,longhorn-extras)

.PHONY: longhorn-down
longhorn-down: ## Remove Longhorn and its Envoy route (reclaims ~350-400 MB)
	$(call argocd-delete,longhorn-extras)
	$(call argocd-delete,longhorn)

.PHONY: inkless-up
inkless-up: ## Deploy Aiven Inkless (diskless Kafka) via ArgoCD manual sync (~1.1 GB; requires garage-bootstrap; do after make up)
	$(call argocd-sync,inkless)

.PHONY: inkless-down
inkless-down: ## Remove Aiven Inkless and PostgreSQL (reclaims ~1.1 GB RAM; does not delete Garage bucket)
	$(call argocd-delete,inkless)

.PHONY: kargo-up
kargo-up: ## Deploy Kargo promotion-orchestration engine via ArgoCD manual sync (~250-450 MB; do after make up)
	$(call argocd-sync,kargo-extras)
	$(call argocd-sync,kargo)
	$(call argocd-sync,kargo-networkpolicy)
	$(call argocd-sync,kargo-project)

.PHONY: kargo-down
kargo-down: ## Remove Kargo and its Envoy route (reclaims ~250-450 MB)
	$(call argocd-delete,kargo-project)
	$(call argocd-delete,kargo-networkpolicy)
	$(call argocd-delete,kargo-extras)
	$(call argocd-delete,kargo)
