# CHARTER.md target end-state + README/CHARTER cloud-backend status — fix stale drift

**Planner-check fallback run** (ROADMAP.md's `Now / next` lane was fully starved this
run, and the coverage/hardening lane's obvious gaps had already been closed by
concurrent routine runs — `tests/validate-scripts.bats` in this session's earlier PR
#431, `tests/hook-scripts-coverage.bats` negative-path cases in PR #432. Per ROADMAP.md
rule #9's fallback chain, the planner-check lane — diffing CHARTER.md's stated
end-state against the actual repo state — surfaced real drift instead of an idle
declaration.)

## Gap found

CHARTER.md's `## Target end-state` section labelled two initiative groups **"(planned)"**
when both are, in fact, fully built:

- **"Always-on next wave" (Kyverno, Argo Rollouts, Velero, Trivy Operator)** — CHARTER
  Objective O1 ("Tier 1 next-wave deployed... auto-synced ArgoCD `Application`s with
  their own ADR, real-metric Grafana dashboard, and bats coverage") is due 2026-12-31.
  Every ROADMAP.md item building these four is checked `[x]`: the Kyverno engine +
  ClusterPolicies, the Velero controller + Schedules, the Argo Rollouts controller +
  capstone Rollout overlay, and Trivy Operator — each with its own ADR (0019/0020/0021/
  0022), `grafana/dashboards/lab-<name>.json`, and `tests/<name>*.bats` coverage. A full
  local `make ci` run this session (1848 bats assertions, 0 failures, using a correctly
  installed toolchain — see PR #431's `docs/done/` entry) confirms all four Applications
  are present, auto-synced, and pass their structural tests. None of this is "planned"
  any longer.
- **"Heavy / on-demand" (TiDB, Harbor, Istio ambient + Kiali, Longhorn)** — each has a
  complete `gitops/platform/<name>.yaml` Application (non-auto-synced, matching
  ADR-0003's on-demand pattern) and a `make <name>-up` / `<name>-down` Makefile target.
  The code is finished; only the live deployment is deliberately deferred (by design —
  never two full stacks at once on the 12 GB budget). "Planned" implied unbuilt; the
  accurate state is "built, brought up on demand."

A second, related gap surfaced while checking CI on this PR: **README.md** (line 16-17)
still said "A cloud backend module is planned (see CHARTER.md → Target end-state) but
not yet built" — flatly false (all five RFC #377 items building `infra/live/oracle/`
are checked `[x]` in ROADMAP.md) and self-contradicting, since it points readers at the
very CHARTER.md section this PR was correcting. Worse, **CHARTER.md's own** "Cloud
backend" bullet (the one README pointed to) was itself a step behind
`infra/live/README.md`'s Status table: it said "unverified against a real account...
never actually run end-to-end," but the Status table (updated 2026-07-15, see
`docs/done/2026-07-15-oracle-backend-live-verification-partial.md`) already records the
tfstate bootstrap, `terragrunt init` against the real S3 API, and the `cluster/` unit's
VCN/subnet/security-list/internet-gateway layer all applying cleanly against a real OCI
tenancy — only the k3s compute instance launch remains blocked, by a transient Oracle
Always Free capacity constraint (`500 Out of host capacity`), not a repo bug.

## What shipped

- CHARTER.md `## Target end-state`: "Always-on next wave" flipped from `(planned, ...)`
  to `(built, ...)`, with a sentence citing the ADR + dashboard + bats triple and
  Objective O1 being met ahead of its date; "Heavy / on-demand" flipped from `(planned)`
  to `(built, on-demand)`, clarifying each is a manual-sync Application with `make
  <name>-up`/`<name>-down`, code-complete but not continuously deployed.
- CHARTER.md "Cloud backend" bullet: `(built, unverified against a real account)` →
  `(built, partially verified against a real account)`, with the specific
  tfstate/terragrunt-init/VCN-layer confirmation and the exact capacity-constraint
  blocker, matching `infra/live/README.md`'s Status table instead of trailing it.
- README.md: replaced the false "planned... not yet built" claim with an accurate
  one-liner pointing at `infra/live/README.md` → Status for the authoritative,
  up-to-date detail rather than duplicating (and re-staling) it in prose here.

Docs-only; no code, manifest, or test changes. `grep` confirms no `scripts/*.sh` or
`tests/*.bats` mechanically depends on the exact wording changed here, so this carries
no drift-check risk; `bash scripts/readme-check.sh` and the full local `make ci` both
pass (1848/1848, full toolchain installed this session).

## PR

https://github.com/tooming/k8s-anywhere/pull/433
