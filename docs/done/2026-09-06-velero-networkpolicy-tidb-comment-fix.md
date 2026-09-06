# Fix a stale namespace list in `gitops/platform/velero-networkpolicy.yaml`'s header comment (post-TiDB-removal drift)

ADR-0004; JANITOR-fallback coverage sweep 2026-09-06, following up on PR #1452's
TiDB/Istio/Kiali/Longhorn removal — checked every `gitops/` file for lingering
references to the removed components and found this one stale header comment;
the child `NetworkPolicy` file itself
(`gitops/velero/networkpolicy/allow-velero-egress-kopia-pv.yaml`) had already
been correctly updated by PR #1452, but the parent `Application` wrapper's own
header comment, listing the same namespace set independently in prose, was
missed.

## What was found

`gitops/platform/velero-networkpolicy.yaml`'s header comment still said:

> Kopia PV-read egress to backed-up namespaces (data/tidb/capstone/vault).

`tidb` no longer exists as a namespace since PR #1452 removed TiDB from the lab
entirely, no replacement. The actual `NetworkPolicy` object this comment
describes (`allow-velero-egress-kopia-pv.yaml`) had already been updated in
that same PR to the real, current set (`data`, `capstone`, `vault`,
`observability`) — but this sibling file's own prose description of the same
policy, in a different file, was missed.

## What was done

Corrected the comment to list the real, current namespace set
(`data/capstone/vault/observability`), matching the child `NetworkPolicy`'s
actual `values:` list exactly, with an inline note on when and why it changed
(mirrors the note style the child file itself already uses).

Checked `tests/networkpolicy-velero.bats` and `tests/velero.bats` directly —
neither had any assertion depending on the stale comment text, so no test
changes were needed.

## Why this is in scope for a JANITOR cycle

A quick, targeted sweep of every `gitops/` file for lingering references to
the components PR #1452 removed (TiDB, Istio ambient mesh + Kiali, Longhorn)
found no dead selectors, no orphaned resources, and no directories left
behind — the removal itself was clean. This one header-comment drift was the
only real finding: prose describing live config had fallen out of sync with
the config it describes, in a file adjacent to (but not the same as) the one
PR #1452 actually touched — exactly the kind of small, easy-to-miss drift a
coverage sweep exists to catch.

## Result

`make ci` passes green (2712+ bats assertions, 0 failures — this change
touches only a comment, no functional NetworkPolicy behavior). No test
changes needed.

## PR

https://github.com/tooming/k8s-anywhere/pull/1462
