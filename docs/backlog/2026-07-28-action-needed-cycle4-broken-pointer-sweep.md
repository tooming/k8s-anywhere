# [Action needed] Now/next still gated; dedicated doc-drift broken-pointer sweep also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on the standing
maintainer-confirmation issues #631, #632, #633 — re-verified this cycle (4th of this run):
all three still open, zero comments, unchanged since 2026-07-21.

## What this run already shipped (earlier cycles this run)

- PR #823 + #824 — planner gap-analysis fallback found and built a real CHARTER
  Objective O5 gap (Istio ambient mesh observability wiring).
- PR #825 — cycle 3's honest record after the upgrade-drafter and janitor STEP 6b
  fallback roles both came back clean (full evidence trail in that PR/file).

## This cycle's fresh angle

Tried the doc-drift-author fallback role's own STEP 2 checks as a dedicated pass — not
just the generic `make ci` readme/lab-ui/markdown-link gates already confirmed green
earlier this run, but its specific "scan `gitops/` for any ArgoCD Application whose
`spec.source.path` references a directory that doesn't exist" check, run directly against
every `kind: Application` manifest in `gitops/` (58 distinct source-path references):

- Three regex hits initially looked broken, all confirmed false positives on inspection:
  `gitops/platform/governance-appset.yaml` and `gitops/platform/networkpolicy-appset.yaml`
  matched on their `template.spec.source.path: "{{gitPath}}"` — an ApplicationSet
  Go-template placeholder resolved per-generator-entry, not a literal path; and
  `gitops/platform/observability-grafana.yaml` matched on a Grafana chart `valuesObject`
  key (`/var/lib/grafana/dashboards/community`, an in-pod filesystem mount path for the
  dashboard sidecar), not a git source path at all.
- All 55 remaining real `spec.source.path` references resolve to an existing directory.

No broken pointer found. Combined with the already-green `readme-check`, `lab-ui-check`,
and markdown-link checks from earlier this run, doc-drift-author's full scope (per its own
STEP 2) is clean. Issue-triage was re-checked too: `gh issue list --state open` still
returns exactly the three standing issues above, each already correctly labeled — nothing
untriaged.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream CVE/release
firing a tracked ADR flip condition; (c) a new GitHub issue of any size to groom.

This is this cycle's honest record, following two real merged deliverables earlier this
run (PR #823/#824, and cycle 3's own record PR #825) — not a substitute for shipping work.
The run continues to the next cycle per `executor.prompt.md` STEP 8.
