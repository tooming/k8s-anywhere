# [Action needed] Cycle 8 of this run — fallback chain exhausted for now

## This run so far

This run has shipped 7 merged PRs so far:

1. [#1620](https://github.com/tooming/k8s-anywhere/pull/1620) — PLANNER-fallback: groomed issue #1619 into a ROADMAP item.
2. [#1621](https://github.com/tooming/k8s-anywhere/pull/1621) — implemented that item: Terraform-provider caching for the Oracle apply workflows.
3. [#1622](https://github.com/tooming/k8s-anywhere/pull/1622) — JANITOR: ROADMAP legacy-item trim, batch 9 (237 lines saved).
4. [#1623](https://github.com/tooming/k8s-anywhere/pull/1623) — JANITOR: batch 10 (156 lines saved).
5. [#1624](https://github.com/tooming/k8s-anywhere/pull/1624) — JANITOR: batch 11 (122 lines saved).
6. [#1625](https://github.com/tooming/k8s-anywhere/pull/1625) — JANITOR currency sweep: Terragrunt `v1.1.4`→`v1.1.5`, using a previously-untried network path (`raw.githubusercontent.com` + git wire protocol, reachable even though `registry.terraform.io`/`get.helm.sh`/per-repo `api.github.com` are not).
7. [#1626](https://github.com/tooming/k8s-anywhere/pull/1626) — JANITOR: batch 12 (33 lines saved), plus a full currency cross-check of every always-on dependency (ArgoCD, Traefik, k3s, cert-manager, Terraform, kustomize, kubeconform, tflint) — all confirmed already at latest stable.

## This cycle's state

- **ROADMAP.md "Now / next":** zero unchecked `[ ]` items.
- **Open issues:** zero.
- **Open PRs:** zero (before this one).
- **🟡 items awaiting an architect RFC:** zero — every `🟡` marker in `ROADMAP.md` is on an already-resolved (`~~🟡~~`) historical entry; none are live.
- **CHARTER.md's two live Objectives:** O2 (default-deny + PSS-restricted) — namespace test coverage matches all 4 always-on namespaces, on track for its 2026-09-30 date. O7 (DORA metrics) — `docs/dora-metrics.md` was refreshed 2026-09-14, on track for its 2026-10-31 date. Neither shows a gap.
- **Doc drift:** `make ci`'s full drift suite (readme-check, lab-ui-check, dependency-tree sync, ADR chart/image-pin sync, dependency-register Last-reviewed sync, dependency-concentration/exit-runbook sync) is green with zero warnings — re-confirmed this cycle. No ArgoCD `Application` has a broken `spec.source.path`.
- **Dependency currency:** every currently-pinned always-on tool this session can verify (network egress to `registry.terraform.io`, `get.helm.sh`, and out-of-scope `api.github.com` repos is blocked, but `raw.githubusercontent.com` and the git wire protocol are not) is confirmed at its real latest stable release as of this cycle — see PR #1626's body for the full list.
- **ROADMAP.md legacy-item trim lens (batches 9–12, this run):** closed out — the remaining duplication left in the file is deliberately kept (a live operational note, a real unmet flip condition, one item with no clean mirror, one already-compact item), not an oversight.

## What's still genuinely blocked (not new — carried from earlier cycles this run)

- **Terraform *provider* version bumps** (as opposed to the CLI or Terragrunt itself): `registry.terraform.io` is confirmed blocked from this sandbox, so a real `terraform init -upgrade` to regenerate `.terraform.lock.hcl` with real per-platform hashes can't run here. See cycle 8's original record,
  [docs/backlog/2026-09-14-action-needed-cycle8-terraform-provider-bumps-blocked.md](2026-09-14-action-needed-cycle8-terraform-provider-bumps-blocked.md).
- **The GitLab→Forgejo rename item** (`ROADMAP.md`, "Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh`"): already marked "closed as moot" (both GitLab and Forgejo were removed entirely 2026-09-07) but its own investigation trail (`docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md`) spans several live-session updates that would need careful reading to safely condense — deferred again this cycle (same as trim batches 9–12) rather than risk losing real history.
- **Oracle Cloud's `500 Out of host capacity`** constraint (issue #406/ADR-0027): unchanged, no new information this cycle — `oracle-cluster-apply-retry.yml`'s hourly retry keeps trying on its own schedule.

## What would open new work

- A new GitHub issue (intake) from the maintainer.
- Oracle Cloud capacity freeing up (unblocks the cloud-backend initiatives CHARTER.md's "Target end-state" section still tracks as partially verified).
- A future session with `registry.terraform.io` reachable, to actually execute the three real Terraform-provider bumps cycle 8 already found and verified were safe (`hashicorp/helm` `3.2.0`→`3.3.0`, `hashicorp/null` `3.3.0`→`3.3.2`, `hashicorp/local` `2.9.0`→`2.9.1`).
- A later cycle in this same run, trying yet another lens (the GitLab→Forgejo item's own careful read is the most concrete candidate named above).

This is cycle 8's honest record, per `executor.prompt.md` STEP 6b's last resort — every fallback role (PLANNER, ARCHITECT, DOC-DRIFT-AUTHOR, TRIAGER, JANITOR) was genuinely tried this cycle and came up clean or already-delivered, not skipped. The run continues (STEP 8) — going back to STEP 1.
