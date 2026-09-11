# DORA metrics — k8s-lab

Computed 2026-09-11T00:27:08Z for the trailing 90-day window (RFC #580).
Regenerate with `make dora-metrics`. All four metrics are re-grounded in this
repo's clusterless, self-merging GitOps model — see RFC #580 for the full
definitions and rationale. A value of "insufficient data" means exactly that: not
enough evidence existed to compute it, never a fabricated number (ADR-0004).

| Metric | Value |
|---|---|
| Deployment frequency | 97.67 deployments/week (1256 in 90d window) |
| Lead time for changes | insufficient data (gh CLI or jq not available) |
| Change failure rate | 9.6% (120/1256 deployments) |
| Time to restore service | insufficient data (gh CLI or jq not available) |
