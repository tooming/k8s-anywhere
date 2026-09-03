# DORA metrics — k8s-lab

Computed 2026-09-03T01:55:53Z for the trailing 90-day window (RFC #580).
Regenerate with `make dora-metrics`. All four metrics are re-grounded in this
repo's clusterless, self-merging GitOps model — see RFC #580 for the full
definitions and rationale. A value of "insufficient data" means exactly that: not
enough evidence existed to compute it, never a fabricated number (ADR-0004).

| Metric | Value |
|---|---|
| Deployment frequency | 90.59 deployments/week (1165 in 90d window) |
| Lead time for changes | insufficient data (gh CLI or jq not available) |
| Change failure rate | 8.9% (104/1165 deployments) |
| Time to restore service | insufficient data (gh CLI or jq not available) |
