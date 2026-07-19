# DORA metrics — k8s-lab

Computed 2026-07-19T11:15:36Z for the trailing 90-day window (RFC #580).
Regenerate with `make dora-metrics`. All four metrics are re-grounded in this
repo's clusterless, self-merging GitOps model — see RFC #580 for the full
definitions and rationale. A value of "insufficient data" means exactly that: not
enough evidence existed to compute it, never a fabricated number (ADR-0004).

| Metric | Value |
|---|---|
| Deployment frequency | 43.47 deployments/week (559 in 90d window) |
| Lead time for changes | insufficient data (gh CLI or jq not available) |
| Change failure rate | 8.2% (46/559 deployments) |
| Time to restore service | insufficient data (gh CLI or jq not available) |
