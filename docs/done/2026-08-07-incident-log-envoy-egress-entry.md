# docs/incident-log.md — add the envoy-egress-allowlist recurrence entry

Executor filler item (ROADMAP rule #9 doc precision; executor.prompt.md STEP 6b
fallback chain — cycle 11, after the Now/next lane remained gated on #631/#633/#1034).

`docs/incident-log.md`'s "Real incident history" table already records the original
2026-08-04 `harbor` NetworkPolicy egress-allowlist incident (PR #968), but this same
run's earlier cleanup (PR #1064) found the identical root-cause pattern had recurred,
undetected, for four more namespaces (`tidb`, `longhorn-system`, `istio-system`,
`kargo`) — a real, distinct incident by the log's own definition (a real root cause
found and fixed), not yet recorded.

Added a new 2026-08-07 row: severity P1 (a NetworkPolicy hole, matching the scheme's
own P1 example), detection method (clusterless static cross-reference, not a
live-cluster investigation this time — distinguishes it honestly from the row above),
root cause (identical to the harbor row), fix (PR #1064, with the addition — unlike
the original harbor fix — of a mechanical recurrence guard), and follow-up (the new
`scripts/envoy-egress-allowlist-check.sh` guard, plus the related preventative
`appset-list-coverage-check` guard from PR #1065).

`make ci` passes, including `tests/incident-log.bats`'s existing structural
assertions (severity scheme, no-fabricated-content check, etc. — all still pass
unchanged).

## PR

https://github.com/tooming/k8s-anywhere/pull/1070
