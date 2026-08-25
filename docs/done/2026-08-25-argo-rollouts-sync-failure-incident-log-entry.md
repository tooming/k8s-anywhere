# docs: log the argo-rollouts sync-failure incident (issue #633, 2026-08-17)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's fifth cycle. "Now / next" remained fully gated
(unchanged: the two GitLab→Forgejo migration items and the capstone
`Deployment` removal, still gated on issue #633 — re-checked, no new
comment) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER
found nothing new this cycle. **No prerequisites — executor may pick up
immediately.**

## The gap

While re-reading issue #633's full comment history (already fetched earlier
this run to confirm the capstone-`Deployment`-removal item is still gated),
found a second real, previously-undocumented incident distinct from the two
k3s-datastore rows already in `docs/incident-log.md`: a 2026-08-17 live-cluster
session found the `argo-rollouts` ArgoCD `Application` had been failing to
sync since 2026-08-11 (namespace never created), first on the same
apiserver/datastore root cause the existing 2026-08-17 P0 row documents, then
— once that was resolved — on a distinct `argocd-repo-server` egress timeout
reaching `argoproj.github.io` from inside the cluster network. This was
investigated and commented on issue #633 but never landed in the incident
log, which exists precisely to capture "what broke, in production-shape
terms, and why" (DORA Pillar 2, per the log's own header).

## The fix

Added a new row to `docs/incident-log.md`'s "Real incident history" table
(2026-08-17, **P1** per the severity scheme's mechanical definition — a
single always-on component, argo-rollouts, was down), documenting both
root-cause layers found and the honest **"Unresolved as of 2026-08-17"**
status — this remote clusterless session has no way to independently
re-verify current live sync health, so per ADR-0004 the entry says exactly
that rather than assuming either a fixed or still-broken state. Added a
matching bats coverage test in `tests/incident-log.bats`.

`make ci`: green (full local run including real `bats`; the two new
assertions in `tests/incident-log.bats` pass alongside the full suite).

## PR

https://github.com/tooming/k8s-anywhere/pull/1314
