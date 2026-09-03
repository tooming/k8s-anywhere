# Pyroscope currency re-check — app `v2.3.0` exists, no matching chart release yet, kept

Continuing this run's coverage sweep, checked Pyroscope's currency for the
first time since 2026-08-10 (the oldest untouched entry in the dependency
register at cycle start).

## What was checked

Directly against live sources (ADR-0004):

- `github.com/grafana/pyroscope/releases/tag/v2.3.0`: real, released 24 Aug —
  a genuine minor app release with real security content (Go 1.25.13,
  `go.etcd.io/etcd/client/pkg/v3` v3.6.14, `golang.org/x/mod` v0.40.0, a
  `nanoid` bump). Its own release notes state it "includes every security
  fix from 2.2.1."
- `github.com/grafana/pyroscope/tags`: `pyroscope-2.2.1` is still the newest
  **chart** tag — no `pyroscope-2.3.0` exists. Confirmed directly: fetching
  `operations/pyroscope/helm/pyroscope/Chart.yaml` at that guessed tag 404s
  (the tag doesn't exist at all, not a path-naming mismatch).

## Decision: kept at chart `2.2.1`

Not a currency gap — the chart release genuinely lags the app release
upstream, so there is nothing to bump `targetRevision` to yet. The current
pin already carries every security fix `v2.3.0` mentions (per that release's
own "includes every security fix from 2.2.1" line, read the other
direction).

## What changed

- `docs/decisions/adr-0034-lgtmp-observability-stack.md`: new Re-evaluation
  log entry.
- `docs/dependency-register.md`: Pyroscope row updated.

No `gitops/` change (correctly — a "confirmed no action needed" finding).
`make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1406
