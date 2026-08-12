# [Action needed] Now/next still gated; ArgoCD Application broken-pointer sweep + script-wiring check both clean

**Date:** 2026-08-12
**Cycle:** 5th cycle this run (after PR #1162 — planner-fallback Q16 rollup item, PR
#1163 — building it, PR #1164 — cycle 3's honest fallback-chain record, PR #1165 —
architect-fallback digest refresh)

## What's blocked

The "Now / next" lane holds the same six unchecked items as every prior cycle this
run, unchanged:

1. **Flip `Application` `repoURL`s to the Forgejo remote** — explicit live-cluster-only
   flip.
2. **Rename `scripts/gitlab-*.sh` → `forgejo-*.sh`** — sequentially blocked on item 1.
3. **Decommission `gitlab/docker-compose.yml`** — sequentially blocked on items 1–2.
4. **`verifyImages` ClusterPolicy Audit → Enforce flip** — gated on standing issue
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (re-checked: `updated_at`
   and comment count unchanged since 2026-08-11).
5. **O4 CI gate — `verify-image-rejection` job** — sequentially blocked on item 4.
6. **Remove legacy capstone `Deployment`** — gated on standing issue
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-checked: same,
   unchanged).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER**: no groomable intake (only #631/#633 open, both correctly labeled
  standing trackers). No un-RFC'd 🟡 item anywhere in ROADMAP.md. No
  `docs/roadmap/incoming/` file.
- **ARCHITECT**: no open `adr-audit`/`rfc` issue; nothing to decide (this run already
  delivered its mandatory digest write this cycle-chain, PR #1165, one cycle prior —
  refreshing it again in the same pass would be churn, not a fresh deliverable).
- **UPGRADE-DRAFTER**: no new components checked this cycle beyond the six already
  reconfirmed current in cycle 4's digest refresh (Envoy Gateway, External Secrets,
  Vault Helm, Trivy Operator, kro, Kargo) — re-running the identical check same-run
  would not surface anything new within minutes of the last pass.
- **DOC-DRIFT-AUTHOR**: `make readme-check` + `make lab-ui-check` both clean (as every
  prior cycle found). This cycle added a fresh, precise check beyond those two:
  parsed every `gitops/**/*.yaml` file for `kind: Application` and cross-referenced
  every `spec.source.path` (git-path sources only, excluding Helm `chart:` sources)
  against a real on-disk directory — 54 Application git-path sources checked, **zero
  broken pointers** (a naive regex-based first pass over-matched on unrelated `path:`
  keys — Kyverno's liveness-probe path, Grafana's dashboard-sidecar mount path,
  ApplicationSet Go-template `path:` placeholders — corrected by parsing YAML
  structurally and scoping to `Application` resources' `spec.source`/`spec.sources`
  only).
- **TRIAGER**: both open issues already fully labeled.
- **JANITOR**: checked every `scripts/*-check.sh` file is referenced by name in either
  `Makefile` or `.github/workflows/ci.yml` — one apparent miss,
  `idle-issue-guard-check.sh`, investigated and confirmed **not** a real gap: it's
  wired as a Claude Code `PostToolUse` hook via `.claude/settings.json`
  (`bash scripts/idle-issue-guard-hook.sh`, which itself calls
  `idle-issue-guard-check.sh`) — a runtime tool-call guard, not a repo-state drift
  check, so `make ci` wiring was never the right mechanism for it by design (matches
  its own header comment and `tests/hook-scripts-coverage.bats`'s separate coverage
  track for hook scripts). No other unwired check-script or genuine duplication/dead-
  code candidate found.

## What would unblock the standing gates

Unchanged: both #631 and #633 need a live-cluster session with real host headroom to
complete a full pipeline run (build → cosign sign → push to Harbor → Kyverno admission
→, for #633, a Kargo promotion).

This is a real, honest cycle outcome, not an idle declaration — per STEP 8, the run
continues past this point to the next cycle.
