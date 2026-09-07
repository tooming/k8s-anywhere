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

# DR drill blast radius: cluster | machine (see docs/DR.md)
SCOPE ?= cluster

REQUIRED_TOOLS := colima docker k3d kubectl helm terraform terragrunt kustomize argocd yq jq mkcert

##@ General

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: readme-check
readme-check: ## Check README.md is in sync with the Makefile + tools (drift detector)
	@bash scripts/readme-check.sh

.PHONY: lab-ui-check
lab-ui-check: ## Check README.md's Endpoints table matches the IngressRoutes in gitops
	@bash scripts/lab-ui-check.sh

.PHONY: appset-list-coverage-check
appset-list-coverage-check: ## Check networkpolicy-appset/governance-appset list-generators cover every real leaf dir
	@bash scripts/appset-list-coverage-check.sh

.PHONY: workflow-timeout-check
workflow-timeout-check: ## Check every .github/workflows/*.yml job sets an explicit timeout-minutes
	@bash scripts/workflow-timeout-check.sh

.PHONY: roadmap-check
roadmap-check: ## Check ROADMAP.md has no inline planner notes (per-run narrative belongs in docs/backlog/)
	@bash scripts/roadmap-check.sh

.PHONY: markdown-links-check
markdown-links-check: ## Check every relative [text](path) link in tracked *.md files resolves
	@bash scripts/markdown-links-check.sh

.PHONY: ci-parity-check
ci-parity-check: ## Check make ci and .github/workflows/ci.yml run the identical set of gate scripts
	@bash scripts/ci-parity-check.sh

.PHONY: securitycontext-tests-check
securitycontext-tests-check: ## Check tests/securitycontext.bats stays frozen (new PSS tests go in securitycontext-<scope>.bats)
	@bash scripts/securitycontext-tests-check.sh

.PHONY: networkpolicy-tests-check
networkpolicy-tests-check: ## Check tests/networkpolicy.bats stays baseline-only (per-namespace tests go in networkpolicy-<scope>.bats)
	@bash scripts/networkpolicy-tests-check.sh

.PHONY: yq-raw-check
yq-raw-check: ## Check bats tests read yq scalars via yqs() (no bare yq calls — variant-quoting guard)
	@bash scripts/yq-raw-check.sh

.PHONY: yq-variant-guard-check
yq-variant-guard-check: ## Check scripts/*.sh calling mikefarah-only yq syntax (eval-all/eval/ea) guard it via require_mikefarah_yq
	@bash scripts/yq-variant-guard-check.sh

.PHONY: git-fixture-isolation-check
git-fixture-isolation-check: ## Check git-fixture bats tests unset GIT_* (so make ci survives running from a hook)
	@bash scripts/git-fixture-isolation-check.sh

.PHONY: bats-shellcheck-duplication-check
bats-shellcheck-duplication-check: ## Check no bats test invokes shellcheck directly (that's make lint's job)
	@bash scripts/bats-shellcheck-duplication-check.sh

.PHONY: securitycontext-tests-mark
securitycontext-tests-mark: ## Refresh tests/.securitycontext-titles — run ONLY after an intentional rename/edit of a monolith test
	@grep -oE '^@test "[^"]*"' tests/securitycontext.bats | sort > tests/.securitycontext-titles
	@echo "  ok  tests/.securitycontext-titles refreshed ($$(wc -l < tests/.securitycontext-titles | tr -d ' ') titles)"

.PHONY: drift-detectors-tests-check
drift-detectors-tests-check: ## Check tests/drift-detectors.bats stays frozen (new drift checks go in drift-<scope>.bats)
	@bash scripts/drift-detectors-tests-check.sh

.PHONY: drift-detectors-tests-mark
drift-detectors-tests-mark: ## Refresh tests/.drift-detectors-titles — run ONLY after an intentional rename/edit of a monolith test
	@grep -oE '^@test "[^"]*"' tests/drift-detectors.bats | sort > tests/.drift-detectors-titles
	@echo "  ok  tests/.drift-detectors-titles refreshed ($$(wc -l < tests/.drift-detectors-titles | tr -d ' ') titles)"

.PHONY: hook-scripts-coverage-tests-check
hook-scripts-coverage-tests-check: ## Check tests/hook-scripts-coverage.bats stays frozen (new hook coverage goes in hook-scripts-<scope>.bats)
	@bash scripts/hook-scripts-coverage-tests-check.sh

.PHONY: hook-scripts-coverage-tests-mark
hook-scripts-coverage-tests-mark: ## Refresh tests/.hook-scripts-coverage-titles — run ONLY after an intentional rename/edit of a monolith test
	@grep -oE '^@test "[^"]*"' tests/hook-scripts-coverage.bats | sort > tests/.hook-scripts-coverage-titles
	@echo "  ok  tests/.hook-scripts-coverage-titles refreshed ($$(wc -l < tests/.hook-scripts-coverage-titles | tr -d ' ') titles)"

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

.PHONY: probe-timeout-check
probe-timeout-check: ## Check every explicit livenessProbe/readinessProbe/startupProbe has timeoutSeconds >= 5 (drift detector)
	@bash scripts/probe-timeout-check.sh

.PHONY: adr-followup-check
adr-followup-check: ## Check no ADR/CHARTER.md/WAYS-OF-WORKING.md carries a stale unchecked "Follow-up:" promise (drift detector)
	@bash scripts/adr-followup-check.sh

.PHONY: adr-chart-version-sync-check
adr-chart-version-sync-check: ## Check every ADR that self-declares its Chart + version note as a live pin mirror actually matches the gitops targetRevision (drift detector)
	@bash scripts/adr-chart-version-sync-check.sh

.PHONY: adr-image-pin-sync-check
adr-image-pin-sync-check: ## Check every ADR that self-declares a "pinned official image" note actually matches its live manifest's image tag (drift detector)
	@bash scripts/adr-image-pin-sync-check.sh

.PHONY: context-doc-version-sync-check
context-doc-version-sync-check: ## Check docs/decisions/context.md's tracked version citations match their live gitops pins (drift detector; currently tracks zero citations — Grafana, Pyroscope, KRO, and ACK were all removed, candidate for retirement)
	@bash scripts/context-doc-version-sync-check.sh

.PHONY: dependency-register-check
dependency-register-check: ## Check docs/dependency-register.md's "Last reviewed" cells aren't staler than their cited ADRs' own Re-evaluation logs (drift detector)
	@bash scripts/dependency-register-check.sh

.PHONY: dependency-concentration-sync-check
dependency-concentration-sync-check: ## Check every dependency-register.md org backing 2+ rows is named in dependency-concentration.md (drift detector)
	@bash scripts/dependency-concentration-sync-check.sh

.PHONY: dependency-exit-runbooks-sync-check
dependency-exit-runbooks-sync-check: ## Check every dependency-concentration.md group and dependency-register.md row has a matching mention in dependency-exit-runbooks.md (drift detector)
	@bash scripts/dependency-exit-runbooks-sync-check.sh

.PHONY: docs-done-pr-link-check
docs-done-pr-link-check: ## Check every docs/done/*.md file's "## PR" section is backfilled with a real PR link, not left on the placeholder (drift detector)
	@bash scripts/docs-done-pr-link-check.sh

.PHONY: kustomize-orphan-check
kustomize-orphan-check: ## Check every file next to a kustomization.yaml is referenced by it (no dead/orphaned manifests, drift detector)
	@bash scripts/kustomize-orphan-check.sh

.PHONY: ingressroute-web-tls-check
ingressroute-web-tls-check: ## Check no Traefik IngressRoute combines plain-HTTP `web` with a `tls:` stanza (silently breaks web routing, drift detector)
	@bash scripts/ingressroute-web-tls-check.sh

.PHONY: yqs-lib-check
yqs-lib-check: ## Check no scripts/*.sh defines its own local yqs() helper instead of sourcing scripts/lib/yq.sh (drift detector)
	@bash scripts/yqs-lib-check.sh

.PHONY: ok-bad-lib-check
ok-bad-lib-check: ## Check no scripts/*.sh defines its own local drift-setting bad() instead of sourcing scripts/lib/colors.sh (drift detector)
	@bash scripts/ok-bad-lib-check.sh

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

.PHONY: stale-prs-check
stale-prs-check: ## List open agent-branch PRs that are CI-green but missing the self-reviewed label (STEP 1b helper)
	@bash scripts/stale-prs-check.sh

.PHONY: ci
ci: ## Run every clusterless gate: lint + validate + test + drift checks
	@bash scripts/lint.sh
	@bash scripts/validate-manifests.sh
	@bash scripts/validate-kustomize.sh
	@bash scripts/validate-terraform.sh
	@bash scripts/test.sh
	@bash scripts/readme-check.sh
	@bash scripts/lab-ui-check.sh
	@bash scripts/appset-list-coverage-check.sh
	@bash scripts/workflow-timeout-check.sh
	@bash scripts/roadmap-check.sh
	@bash scripts/markdown-links-check.sh
	@bash scripts/securitycontext-tests-check.sh
	@bash scripts/networkpolicy-tests-check.sh
	@bash scripts/yq-raw-check.sh
	@bash scripts/yq-variant-guard-check.sh
	@bash scripts/git-fixture-isolation-check.sh
	@bash scripts/routines-check.sh
	@bash scripts/routines-author-check.sh
	@bash scripts/helm-chart-pin-check.sh
	@bash scripts/argocd-crd-ssa-check.sh
	@bash scripts/probe-timeout-check.sh
	@bash scripts/adr-followup-check.sh
	@bash scripts/adr-chart-version-sync-check.sh
	@bash scripts/adr-image-pin-sync-check.sh
	@bash scripts/context-doc-version-sync-check.sh
	@bash scripts/dependency-register-check.sh
	@bash scripts/dependency-concentration-sync-check.sh
	@bash scripts/dependency-exit-runbooks-sync-check.sh
	@bash scripts/docs-done-pr-link-check.sh
	@bash scripts/kustomize-orphan-check.sh
	@bash scripts/ingressroute-web-tls-check.sh
	@bash scripts/yqs-lib-check.sh
	@bash scripts/ok-bad-lib-check.sh
	@bash scripts/drift-detectors-tests-check.sh
	@bash scripts/hook-scripts-coverage-tests-check.sh
	@bash scripts/bats-shellcheck-duplication-check.sh
	@bash scripts/ci-parity-check.sh

.PHONY: install-hooks
install-hooks: ## Wire up .githooks/ as the local git hooks directory (run once per clone)
	@git config core.hooksPath .githooks
	@chmod +x .githooks/pre-push .githooks/post-merge
	@echo "  ok  pre-push hook installed (lint runs before every push; full make ci runs in GitHub Actions)"

.PHONY: preflight
preflight: ## Check required CLI tools are installed
	@missing=0; for t in $(REQUIRED_TOOLS); do \
		if command -v $$t >/dev/null 2>&1; then printf "  ok    %s\n" "$$t"; \
		else printf "  MISS  %s\n" "$$t"; missing=1; fi; done; \
	if [ $$missing -eq 1 ]; then echo "Some tools missing."; fi

##@ Full lifecycle

.PHONY: up
up: ## Bootstrap the ENTIRE lab from scratch, in order (see docs/DR.md)
	$(MAKE) colima-up
	$(MAKE) cluster-up
	$(MAKE) coredns-host-alias
	$(MAKE) argocd
	$(MAKE) root-app
	$(MAKE) coredns-nip-io-rewrite
	@echo ""
	@echo "--- verifying every always-on workload is actually Running+Ready ---"
	@UI="UIs on :8080 — ArgoCD http://argocd.127.0.0.1.nip.io:8080 · run 'make creds' for logins"; \
		if bash scripts/lab-health-check.sh; then \
			echo ""; echo "✅ lab up — every always-on workload is healthy. $$UI"; \
		else \
			echo ""; echo "⚠️  bootstrap complete, but some always-on workloads are NOT healthy (see ✗ above). Run 'make health' to re-check. $$UI"; \
		fi

.PHONY: down
down: ## Stop everything (cluster + Colima). Data on PVCs/volumes is kept.
	-cd $(LIVE)/cluster && terragrunt destroy -auto-approve
	-colima stop

##@ Runtime (Colima)

# vm-type qemu, not vz (Apple Virtualization.framework): vz's networking degrades
# under sustained load — pod egress to the internet (Harbor/Helm-chart-repo fetches,
# argo-rollouts' Helm repo) intermittently black-holes 10-20+ minutes into a session,
# even though the same targets are instant from the Mac host itself. Reproduced
# 2026-09-06 investigating issue #633 (docs/incident-log.md) and matches known,
# unresolved upstream reports (abiosoft/colima#952, #552, lima-vm/lima#1333) — "VZ is
# flagged as experimental and causes problems," qemu is the documented workaround.
.PHONY: colima-up
colima-up: ## Start the Colima VM (docker runtime) + raise inotify limits
	colima status >/dev/null 2>&1 || colima start --cpu $(COLIMA_CPU) --memory $(COLIMA_MEM) --disk $(COLIMA_DISK) --vm-type qemu --mount-type virtiofs
	@colima ssh -- sudo sysctl -w fs.inotify.max_user_instances=8192 fs.inotify.max_user_watches=1048576 >/dev/null 2>&1 || true

.PHONY: colima-down
colima-down: ## Stop the Colima VM
	colima stop

.PHONY: colima-status
colima-status: ## Show Colima VM status
	colima status

##@ Terraform state (off-cluster S3)

.PHONY: tfstate-oracle-up
tfstate-oracle-up: ## Bootstrap the oracle backend's off-cluster Garage on a separate Always Free AMD Micro instance (ADR-0027; must precede any terragrunt apply under infra/live/oracle/)
	bash scripts/tfstate-oracle-bootstrap.sh

.PHONY: tfstate-oracle-down
tfstate-oracle-down: ## Terminate the oracle backend's tfstate instance (real OCI teardown, not just a stop — re-run tfstate-oracle-up to recreate)
	@INSTANCE_ID=$$(oci compute instance list --compartment-id "$$OCI_COMPARTMENT_ID" --display-name tfstate-oracle --lifecycle-state RUNNING --query 'data[0].id' --raw-output 2>/dev/null); \
	if [ -n "$$INSTANCE_ID" ] && [ "$$INSTANCE_ID" != "null" ]; then \
		oci compute instance terminate --instance-id "$$INSTANCE_ID" --preserve-boot-volume false --force; \
	else \
		echo "no running tfstate-oracle instance found"; \
	fi

##@ Cluster (k3d via Terraform/Terragrunt)

.PHONY: cluster-up
cluster-up: ## Create the k3d cluster
	cd $(LIVE)/cluster && terragrunt apply -auto-approve

.PHONY: cluster-down
cluster-down: ## Destroy the k3d cluster
	cd $(LIVE)/cluster && terragrunt destroy -auto-approve

.PHONY: coredns-host-alias
coredns-host-alias: ## Teach CoreDNS to resolve host.k3d.internal -> docker gateway (k3d 5.x on Colima omits this)
	@bash scripts/coredns-host-alias.sh host-alias

.PHONY: coredns-nip-io-rewrite
coredns-nip-io-rewrite: ## Teach CoreDNS to resolve *.127.0.0.1.nip.io -> Traefik's in-cluster Service (needed for in-cluster clients; issue #633/PR #1323)
	@bash scripts/coredns-host-alias.sh nip-io-rewrite

##@ Bootstrap (day-0, imperative seam)

.PHONY: argocd
argocd: ## Install ArgoCD (Helm via Terraform)
	cd $(LIVE)/argocd && ( \
		terragrunt state list 2>/dev/null | grep -qx 'helm_release.argocd' || { \
			helm -n argocd status argocd >/dev/null 2>&1 && terragrunt import helm_release.argocd argocd/argocd >/dev/null || true; \
		}; \
		terragrunt apply -auto-approve \
	)

.PHONY: root-app
root-app: ## Plant the ArgoCD app-of-apps (everything else syncs from here)
	kubectl apply -f gitops/bootstrap/root-app.yaml

##@ ArgoCD access

.PHONY: argocd-password
argocd-password: ## Print the ArgoCD initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

.PHONY: creds
creds: ## Print all lab UI logins (reads live secrets; needs the cluster up)
	@a=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d); echo "ArgoCD   admin / $${a:-<cluster down>}    http://argocd.127.0.0.1.nip.io:8080"

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

.PHONY: health
health: ## Assert every always-on pod + workload is actually Running+Ready (exit 1 if not)
	@bash scripts/lab-health-check.sh

##@ Disaster recovery (see docs/DR.md)

.PHONY: dr-test
dr-test: ## DR drill: destroy + rebuild from scratch + verify. SCOPE=cluster|machine (default cluster)
	bash scripts/dr-test.sh $(SCOPE)

.PHONY: dr-verify
dr-verify: ## Assert the lab is healthy end-to-end (real checks, no rebuild)
	bash scripts/dr-verify.sh

.PHONY: dr-destroy
dr-destroy: ## Tear the lab down to a clean slate (the 'disaster' only). SCOPE=cluster|machine
	bash scripts/dr-destroy.sh $(SCOPE)

##@ Metrics (on-demand, clusterless)

.PHONY: dora-metrics
dora-metrics: ## Compute DORA metrics from git/CI history -> docs/dora-metrics.md (RFC #580, on-demand only)
	bash scripts/dora-metrics.sh

.PHONY: dependency-maintenance-check
dependency-maintenance-check: ## Report how long since each dependency-register.md repo last committed (DORA Q15, on-demand only)
	bash scripts/dependency-maintenance-check.sh

##@ On-demand components (heavy; not auto-synced — bring up manually)

# No heavy on-demand components remain (Harbor, Kargo, and KEDA — the last three —
# were all removed/converted-away by 2026-09-07; Istio, Longhorn, TiDB, and Trivy
# Operator went earlier). The argocd-sync/argocd-delete/ondemand-guard macros this
# section used to define (for the *-up/*-down targets that called them) were dropped
# alongside the last component that used them — nothing left to call them. If a
# future component adopts the on-demand pattern again, resurrect them from git
# history rather than reinventing the shape.

.PHONY: ondemand-budget-check
ondemand-budget-check: ## Report which on-demand units are live + flag orphaned namespaces (no heavy units currently tracked; see scripts/ondemand-budget-check.sh)
	@bash scripts/ondemand-budget-check.sh

.PHONY: k3s-datastore-health-check
k3s-datastore-health-check: ## Report k3s embedded datastore (SQLite/kine) health: size, compaction gap, Slow SQL volume (2026-08-11 incident, docs/incident-log.md)
	@bash scripts/k3s-datastore-health-check.sh

