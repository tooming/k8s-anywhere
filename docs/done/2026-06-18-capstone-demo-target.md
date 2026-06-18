# 2026-06-18 — make capstone-demo + scripts/capstone-demo.sh

**Branch:** `auto/capstone-demo-target`
**PR:** TBD (opened by this run)
**ROADMAP item:** `make capstone-demo + scripts/capstone-demo.sh` (CHARTER Objective O6, RFC #215)

## What was delivered

New `scripts/capstone-demo.sh` implementing the four-step capstone pipeline check
per RFC #215 §Decision:

1. **capstone ArgoCD Application Healthy** — `argocd app wait capstone --health --timeout 120`
2. **capstone ExternalSecret Ready** — `kubectl -n capstone get externalsecret` jsonpath poll (30 s)
3. **capstone HTTP 200** — `curl http://capstone.127.0.0.1.nip.io:8000/`
4. **Tempo trace for `service.name=capstone`** — `kubectl -n observability port-forward svc/tempo-query-frontend 3100:3100` + `/api/search` (5-min OS-portable look-back)

The script enforces the **900 s (15 min) Objective O6 budget**, prints a summary table after all steps, and exits 1 on any failure or budget overrun.

New `make capstone-demo` phony target in a new `##@ Capstone` Makefile section calling `bash scripts/capstone-demo.sh`. Makefile change approved by RFC #215 (binding architect decision per WAYS-OF-WORKING.md §2).

New `tests/capstone-demo.bats` with 18 clusterless structural assertions covering:
- script existence + executability
- 900 s budget constant + budget-exceeded path + exit 1
- `argocd app wait capstone --health --timeout 120` invocation
- ExternalSecret + `Ready` condition check
- `capstone.127.0.0.1.nip.io` URL + HTTP 200 assertion
- `tempo-query-frontend` port-forward + `service.name=capstone` query
- OS-portable date arithmetic (`-v-5M` + `300`)
- summary table output
- Makefile target wiring (target exists, invokes script, .PHONY declared)

`docs/DR.md` updated with a `## Capstone demo (make capstone-demo)` section documenting prerequisites, the four steps, and the 900 s budget.

## Why

CHARTER Objective O6 requires a single command that exercises the end-to-end capstone
pipeline within a 900 s wall-clock budget — proving the system can be demonstrated
from a cold shell. RFC #215 specified exactly this shape.
