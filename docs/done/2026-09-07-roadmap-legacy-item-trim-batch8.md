# ROADMAP.md legacy `[x]` item trim — batch 8

Continuing batches 1–7
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md)
through
[docs/done/2026-09-07-roadmap-legacy-item-trim-batch7.md](2026-09-07-roadmap-legacy-item-trim-batch7.md)).
JANITOR-fallback cleanup (executor STEP 6b).

## What was done

Trimmed 3 more legacy items — each verified against its real `docs/done/`
mirror before touching the ROADMAP text:

- **KEDA admission webhook TLS — wire to cert-manager's `k8s-lab-ca`** →
  [docs/done/2026-07-17-keda-webhook-cert-manager-tls.md](2026-07-17-keda-webhook-cert-manager-tls.md)
  (PR #458). A high-quality independent writeup (exact chart field paths
  verified against the pinned chart source, wave-move rationale, bats
  coverage, docs updated) matching the ROADMAP spec exactly.
- **`argo-cd` Helm chart major bump — `9.7.1` → `10.2.1`** →
  [docs/done/2026-07-28-argocd-chart-bump-9-7-1-to-10-2-1.md](2026-07-28-argocd-chart-bump-9-7-1-to-10-2-1.md)
  (PR #788, closes RFC #785).
- **`docs/dependency-register.md` — add rows for ADR-0033 (GitLab) and
  ADR-0034 (LGTMP observability internals)** →
  [docs/done/2026-08-07-dependency-register-adr-0033-0034-rows.md](2026-08-07-dependency-register-adr-0033-0034-rows.md)
  (PR #1076).

Each trimmed item's full inline text replaced with the established
short-pointer format. No information lost — the full detail already lived
in the linked `docs/done/` files, confirmed equivalent by reading all three
before editing.

## Result

`ROADMAP.md`: 2371 → 2322 lines (49 lines saved from 3 items). ~148 legacy
items remain for future bounded cycles to continue against.

No `gitops/` change. `make ci` fully clean (exit 0, zero `not ok` lines).

## PR

https://github.com/tooming/k8s-anywhere/pull/1496 (chore/roadmap-legacy-item-trim-batch8)
