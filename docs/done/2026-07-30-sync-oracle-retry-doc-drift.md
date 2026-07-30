# Fix stale claim in infra/live/README.md's Oracle Status row about the capacity-retry mechanism

`infra/live/README.md`'s Status table (`oracle/` row) described the retry mechanism for
Oracle's Always Free Ampere A1 host-capacity constraint as manual: "Since the GitHub
Actions path only needs `gh workflow run`/`gh run view` — plain GitHub API calls, not
`*.oraclecloud.com` — the autonomous executor routine can now retry this itself despite
its own sandbox's egress restrictions."

This is stale/incomplete. `.github/workflows/oracle-cluster-apply-retry.yml` already
exists (added in PR #422, "ci: add hourly scheduled retry for the oracle cluster
instance launch", merged 2026-07-15) and runs on `cron: "17 * * * *"` — fully
automated, hourly, treating `Out of host capacity` as an expected non-alerting outcome
(any other failure still fails loudly). It has been retrying the launch every hour for
15 days as of this fix. Neither `infra/live/README.md` nor
`docs/decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md` mentioned this
workflow or its schedule anywhere (verified via grep — zero matches for
"retry"/"cron"/"hourly"/"schedule" in either file before this fix).

The practical risk: a future executor session reading this row could conclude it needs
to manually `gh workflow run oracle-cluster-apply.yml` to keep retrying — redundant
work duplicating what the repo already does for itself every hour, and potentially
confusing/misleading about the actual automation state (ADR-0004 risk: the doc
implicitly asserted "retry" meant a manual, executor-driven action, when it's actually
already unattended).

## Fix

Updated the `oracle/` row's "Not yet verified" sentence to name
`oracle-cluster-apply-retry.yml` and its hourly cron schedule directly, and to state
explicitly that no executor action is needed to keep retrying. No topology/decision
change — ADR-0027's actual decision (Oracle Always Free + k3s as the first cloud
backend) is unaffected; this is a pure doc-precision fix. `docs/dependency-tree.md` has
no Oracle-specific content to update (it's a `gitops/` graph doc; `infra/` bootstrap
tooling isn't in its scope).

`make ci` passes (2340 assertions, 0 failures; `markdown-links-check` confirms the new
relative link to `oracle-cluster-apply-retry.yml` resolves).

## PR

(filled in after PR creation)
