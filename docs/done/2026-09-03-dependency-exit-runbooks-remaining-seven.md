# Extend `docs/dependency-exit-runbooks.md` to the remaining seven single-tool rows

`docs/dependency-exit-runbooks.md` (closing [`docs/dora-audit-readiness.md`](../dora-audit-readiness.md)
Q17's named gap) previously covered the three upstream-org concentration groups from
[`docs/dependency-concentration.md`](../dependency-concentration.md) plus the four
highest-blast-radius of the eleven single-tool rows in
[`docs/dependency-register.md`](../dependency-register.md) (Cilium, Garage, Envoy
Gateway, cert-manager) — its own "Scope of this slice" note honestly named the
remaining seven single-tool rows (Terraform/Terragrunt, RabbitMQ, Valkey, KEDA,
Forgejo, kube-state-metrics, node-exporter) as real, separately-scoped future work,
deferred only to respect WAYS-OF-WORKING.md §3's per-PR size discipline.

This closes that remainder: added one terse paragraph per tool (mechanically /
fork-and-repoint-or-bigger / alternative-evaluated, same shape as the existing
four-tool section) under a new "Remaining single-tool rows (the other seven)"
section. `docs/dependency-exit-runbooks.md` now covers all 11 single-tool rows named
in the register's criticality column, plus all three concentration groups — full
coverage of Q17's scope for the first time.

Updated the file's own "Scope of this file" intro and "Keeping this in sync" closing
section to reflect this: the register single-tool-row half of this file's sync is
still not mechanically guarded going forward (a future new register row could still
silently go un-runbooked — same gap shape as before, just with a currently-empty
backlog instead of a seven-row one), stated honestly rather than overclaimed as fixed.

No new mitigation invented — same as the original four-tool slice, this only writes
down first-response steps for an exit that isn't happening; the actual mitigation is
still ADR-0001's GitOps-repointing design and the real, executed
Artifactory→Harbor/GitLab→Forgejo/Redis→Valkey precedents each new paragraph cites
directly. `make ci` stays green (the `dependency-exit-runbooks-sync-check.sh`
concentration-group check is unaffected — it only checks concentration groups, not
single-tool-row coverage, so this addition doesn't change its behavior).

## PR

(filled in after PR creation)
