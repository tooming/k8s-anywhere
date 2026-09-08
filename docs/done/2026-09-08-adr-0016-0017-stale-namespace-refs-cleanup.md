# Fix stale `vault`/`external-secrets` (and other pre-2026-09-07-removal) namespace references in ADR-0016 and ADR-0017's per-namespace tables

Found live 2026-09-08 (planner gap analysis, Core Value "Docs don't drift" not
upheld): `docs/decisions/adr-0016-default-deny-networkpolicy.md`'s §Scope &
exceptions still stated "this lab is down to exactly 6 always-on
namespaces... `vault`" (should be 4: `argocd`, `cert-manager`, `lab-gateway`,
`lab-demo` — ADR-0042/CHARTER.md's current count) and its "Relationship to
existing ADRs" / carve-out prose was otherwise fine. `docs/decisions/
adr-0017-pod-security-standards-restricted.md`'s per-namespace profile table
still carried live-looking rows for `vault`, `external-secrets`, `capstone`,
`storage` (Garage), `kyverno`, `velero`, `argo-rollouts`, `kargo`,
`capstone-pipeline`, and `harbor` — every one of those namespaces was removed
entirely 2026-09-06/2026-09-07 (ADR-0042 and the earlier simplification round,
commit 319d6b2/#1497), but neither ADR's table was updated when those removal
PRs landed (confirmed via `git log -- <file>`: #1510 never touched either
file). This is exactly the same drift class ADR-0016's own 2026-08-10
"Re-evaluation log" entry already fixed once for the `artifactory` namespace
— same fix pattern, same file: correct ADR-0016's namespace-count enumeration
to 4 (with a dated Re-evaluation log entry per that precedent), and delete
ADR-0017's now-stale carve-out rows for every removed namespace (add a dated
Re-evaluation log entry there too if useful, or a one-line note next to the
remaining `argocd`/`lab-gateway`/`lab-demo`/`cert-manager`/`kube-system` rows
stating the table is now current as of today). Docs-only, no code/manifest
change, no `make ci` gate affected beyond the existing markdown-only lint —
clusterless-deliverable, single-PR-sized. Not a case ADR-0016/0017's own
"Files this work touches" tables need editing (those already list the ADR
files themselves as in-scope for updates).

## What was done

- **`docs/decisions/adr-0016-default-deny-networkpolicy.md`**:
  - §Scope & exceptions' live-namespace enumeration corrected from "6 always-on
    namespaces... `vault`" to the real 4 (`argocd`, `cert-manager`,
    `lab-gateway`, `lab-demo`); `external-secrets` and `vault` moved into the
    "removed, no replacement" parenthetical alongside the other
    2026-09-06/2026-09-07 removals.
  - §"Per-workload explicit-allow policies"'s naming-convention example swapped
    off a now-nonexistent `gitops/vault/networkpolicy/allow-vault-from-eso.yaml`
    path onto a real, currently-live one
    (`gitops/cert-manager/networkpolicy/allow-cert-manager-webhook-from-apiserver.yaml`)
    — verified directly against the repo before citing it (ADR-0004).
  - Added a dated `## Re-evaluation log` entry (2026-09-08) recording the
    trigger, the correction, and the flip condition (none pending — closed
    record correction), mirroring the ADR's own 2026-08-10 `artifactory`
    precedent.
- **`docs/decisions/adr-0017-pod-security-standards-restricted.md`**:
  - Deleted the ten now-stale per-namespace-table rows: `capstone`, `storage`
    (Garage), `vault`, `kyverno`, `velero`, `argo-rollouts`,
    `external-secrets`, `kargo`, `capstone-pipeline`, `harbor`. The table now
    lists only the lab's real 4 always-on namespaces plus `kube-system`
    (`argocd`, `lab-gateway`, `lab-demo`, `cert-manager`), verified directly
    against `gitops/` before editing.
  - Dropped the `lab-demo` row's dead "or is superseded by the capstone-built
    image" flip-condition clause (capstone no longer exists to supersede
    anything) — the row's live condition (the upstream
    `jaegertracing/example-hotrod` image shipping a non-root UID) is
    unaffected and still open, unchanged from the 2026-07-26 currency check
    already recorded in the Re-evaluation log.
  - Added a dated `## Re-evaluation log` entry (2026-09-08) recording the
    trigger, the correction, and the flip condition (none pending), same
    shape as ADR-0016's 2026-08-10 entry.
- Left untouched (out of scope, historical record not a live-state claim):
  ADR-0017's "Status" line ("Pilot namespace: `capstone`") and "Staged
  rollout" table (`Pilot`/`Fan-out`/`Carve-out` phases citing `capstone`,
  `data`, `storage`, `vault`) — these describe the *original 2026-06 rollout
  plan*, not current state, matching how ADR-0016's own historical
  Re-evaluation log entries keep their original removed-namespace mentions.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green), confirming no mechanical
gate (`adr-followup-check`, `dependency-register-check`, markdown-link-check,
etc.) regressed from these edits.

## PR

[#1514](https://github.com/tooming/k8s-anywhere/pull/1514) (autonomous
scheduled executor run, cycle 2: item picked directly from the
freshly-refilled "Now / next" lane after cycle 1's `plan/*` PR #1513).
