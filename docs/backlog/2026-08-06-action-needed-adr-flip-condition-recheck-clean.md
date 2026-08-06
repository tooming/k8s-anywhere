# [Action needed] Now/next still gated; ADR-0013/ADR-0031 flip-condition re-check clean, full fallback chain confirmed empty

## What's blocked

ROADMAP.md's *Now / next* lane still holds the same 3 unchecked `[ ]` items
this run's many prior cycles today have already found gated:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (last comment
   2026-08-06 07:38 UTC: Vault-sealed + Harbor probe-timeout fixes merged
   (#1038, #1040), but live verification still blocked on host resource
   ceiling during Harbor startup — no new signal since).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (same
   timestamp, same underlying blocker — no real image has landed in Harbor
   yet, so Kargo's Warehouse has nothing to promote).

Re-confirmed via a fresh `list_issues`/`list_pull_requests` call this cycle:
3 open issues (#1034, #633, #631), all standing `[Action required]` gates
with no new comments since the last check; 0 open PRs — nothing in flight to
duplicate.

## Full STEP 6b fallback chain walked this cycle, each confirmed empty

Per `executor.prompt.md` STEP 6b, worked the chain in order rather than
jumping straight to this fallback:

- **PLANNER** — a dedicated gap-analysis pass (CHARTER-vs-repo across ADR
  flip triggers, script/test parity, O2 namespace/NetworkPolicy/PSS
  coverage, O3 DR-restore wiring, O6/O7 tooling, TODO/FIXME sweep, open
  issues) found nothing untracked. No un-RFC'd 🟡 items exist (`grep -n
  "^\- \[ \] 🟡" ROADMAP.md` → zero matches — every 🟡 in the file is prose,
  not a pending item).
- **ARCHITECT** — this week's industry digest
  (`docs/industry/2026-W32-digest.md`) was already refreshed earlier today
  (PR #1046); zero open `adr-audit`-labeled issues (`search_issues
  label:adr-audit state:open` → 0 results). Re-running would only re-confirm
  the same digest with no new findings.
- **UPGRADE-DRAFTER-angle** — re-verified two flip-condition triggers not
  yet individually re-checked this run: `git ls-remote --tags
  pingcap/tidb-operator` shows `v1.6.5` is still the newest tag on the
  `1.6.x` line (ADR-0031's hold — flip condition 4, "line stops receiving
  patches", not tripped); `git ls-remote --tags longhorn/longhorn` shows
  `v1.11.3` is still the newest patch on the intentionally-held `1.11.x` line
  (ADR-0013 §Re-evaluation log deliberately holds one minor behind `1.12.x`
  for its V2 Data Engine surface-area reasons) — no newer `1.11.x` patch
  exists to take as a routine bump. Both pins confirmed current, not stale.
- **DOC-DRIFT-AUTHOR-angle** — ran `make readme-check` and `make
  lab-ui-check` directly: both pass clean (`✓ README in sync with Makefile
  targets + required tools`; `✓ Lab UIs panel matches the host-based
  HTTPRoutes in gitops`). No drift signal to reconcile.
- **TRIAGER-angle** — all 3 open issues already carry `priority:*` +
  `domain:*` (+`readiness:green` on two) labels; nothing ungroomed or
  unlabeled.
- **JANITOR-angle** — prior cycles today already ran a dead-code/orphan-
  script sweep and a full dependency-register audit, both clean (see
  `docs/backlog/2026-08-06-action-needed-post-janitor-sweep-clean.md` and
  `...post-second-janitor-sweep-clean.md`); no new signal to re-check this
  cycle beyond what's already recorded there.

## Assessment

Every clusterless verification angle reachable this cycle — a fresh
independent gap-analysis pass, two previously-unchecked ADR flip-condition
triggers (TiDB Operator, Longhorn), README/lab-UI drift checks run directly,
issue-label triage state, and the already-exhaustive janitor/dependency
sweeps from earlier today — comes back clean. The three gated Now/next items
remain blocked on the same live-cluster facts only a hands-on maintainer
session can supply (a real GitLab CI pipeline run reaching a signed push in
Harbor, a real Kargo promotion).

## What would unblock further work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub
issue (intake); (c) a new upstream CVE/release firing a tracked ADR flip
condition; (d) Harbor reaching a stable state on the live host long enough
for a real CI signing run to complete (per #631's most recent comment, a
host-capacity ceiling, not a remaining code bug).

Per `executor.prompt.md` STEP 8 this is not a stopping point — the run
continues to the next cycle.
