# CHARTER.md target end-state — fix stale "planned" labels

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

## What shipped

Two-paragraph edit to CHARTER.md's `## Target end-state` section:

- "Always-on next wave" flipped from `(planned, ...)` to `(built, ...)`, with a sentence
  citing the ADR + dashboard + bats triple and Objective O1 being met ahead of its date.
- "Heavy / on-demand" flipped from `(planned)` to `(built, on-demand)`, clarifying each
  is a manual-sync Application with `make <name>-up`/`<name>-down`, code-complete but
  not continuously deployed — distinguishing "not built" from "built but deliberately
  not always running."

Docs-only; no code, manifest, or test changes. `grep` confirms no `scripts/*.sh` or
`tests/*.bats` mechanically depends on the exact "(planned)" wording, so this carries no
drift-check risk. `make ci` passes (1848/1848, full toolchain installed this session).

## PR

Autonomous session run — see the `claude/work-until-credits-exhausted-b828b2` branch.
