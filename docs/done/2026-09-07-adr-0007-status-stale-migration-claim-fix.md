# Fix a stale "migration not done" claim in ADR-0007's Status (local backend was already migrated)

Executor cycle, freshly re-oriented after the large 2026-09-06/2026-09-07
lab simplification (PR #1497 — Cilium, Garage, Forgejo, GitLab, Harbor,
Kargo, Argo Rollouts, Velero, Trivy Operator, ACK, moto, KRO, capstone, and
the DR front door all removed entirely, no replacement). `make ci` confirmed
fully green on the new `main` before starting; `ROADMAP.md`'s "Now / next"
lane is completely empty (zero `- [ ]` items anywhere in the file) — this is
a fresh PLANNER-shaped gap-analysis finding against the newly-rewritten
CHARTER.md and ADR set, not a JANITOR-fallback continuation of this run's
earlier work.

## What was found

`docs/decisions/adr-0007-off-cluster-garage-tfstate-backend.md`'s own
Status paragraph (written as part of PR #1497's own removal wave) claimed:
"`infra/live/local/root.hcl` still generates an `s3` backend pointed at
this now-deleted Garage and needs migrating to a local backend ... as a
separate, coordinated follow-up — not done as part of this removal."

This was wrong **at the moment it was written** — checked directly:
`infra/live/local/root.hcl` already uses `backend "local"` (a plain
per-unit state file via `get_terragrunt_dir()`), with an inline comment
explicitly citing "ADR-0007, superseded 2026-09-07" and explaining the local
backend is "the honest simplification." A `grep` across every `infra/live/
local/*.hcl` file and every `infra/modules/*/[a-z]*.tf` file for any
remaining `s3`/Garage backend reference returned nothing. The same PR's own
body (#1497) confirms this under "Critical fix included... Also fixed:
`infra/live/local/root.hcl`'s Terraform state backend" — so the code change
and the ADR's own prose describing that code change directly contradicted
each other from the same commit.

Separately confirmed **not** stale: the Oracle backend
(`infra/live/oracle/root.hcl`) still uses its own distinct, still-live
off-cluster Garage instance (`infra/tfstate-oracle/`,
`scripts/tfstate-oracle-bootstrap.sh`, both still present, the
`tfstate-oracle-up`/`-down` Makefile targets still wired) — this is a
genuinely separate design (RFC #377 item 3, a different Always Free AMD
Micro instance from the one the local backend's now-deleted Garage ran on)
that CHARTER.md itself honestly flags as "may itself need re-examining as a
follow-up," not yet decided either way. Left untouched — a real open
question, not a documentation bug.

## What was fixed

Corrected ADR-0007's Status paragraph to state the local-backend migration
is done (verified directly, not assumed), with an honest note that the
prior text was wrong from the moment it was written, and added the
Oracle-backend clarification so a future reader doesn't conflate the two
backends' very different current states.

## Verification

`make ci` fully clean (exit 0, zero `not ok` lines) — a pure prose
correction to an ADR's Status section, no code/manifest/test touched. The
"no remaining s3/Garage backend reference under infra/live/local/" claim
was verified by direct `grep` in this session, and the Oracle backend's
distinct, untouched state was verified by confirming
`infra/tfstate-oracle/`, its bootstrap script, and its Makefile targets all
still exist.

## PR

https://github.com/tooming/k8s-anywhere/pull/1498 (chore/adr-0007-status-stale-migration-claim-fix)
