# ROADMAP.md legacy `[x]` item trim — batch 7

Continuing the pilot batch, batch 2, batch 3, batch 4, batch 5, and batch 6
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md)).
JANITOR-fallback cleanup (executor STEP 6b) — picked up batch 6's own
suggested widened search ("items with a `docs/done/` mention already
present, in case any of those still carry a lot of inline duplication
alongside the pointer, or the ~150 truly untouched `[x]` items with no
full-text scan performed yet").

## What was done

Trimmed 3 legacy items — each verified against its real `docs/done/` mirror
before touching the ROADMAP text:

- **ArgoCD PSS Phase 1 — namespace warn+audit labels** →
  [docs/done/2026-06-16-argocd-pss-warn-audit.md](2026-06-16-argocd-pss-warn-audit.md)
  (PR #217). This item's own inline text cited
  `docs/done/2026-06-15-argocd-pss-warn-audit.md` (the **wrong date** — off
  by one day from the real file, `2026-06-16`) as "required," meaning this
  item had never actually been trimmed to the pointer format at all — it
  still carried its full original executor build spec verbatim. Verified
  the real mirror's content (files delivered, bats coverage, follow-up gaps
  closed) matches the ROADMAP spec exactly before trimming and correcting
  the date.
- **ArgoCD PSS Phase 2 — securityContext hardening + enforce flip** →
  [docs/done/2026-06-24-argocd-pss-enforce.md](2026-06-24-argocd-pss-enforce.md)
  (PR #268). This mirror is itself just the ROADMAP spec text plus a PR
  link (not an independent post-hoc writeup) — still a real, verifiable
  record with no information lost by trimming the ROADMAP copy.
- **PSS-restricted hardening — `external-secrets` namespace** →
  [docs/done/2026-06-20-pss-external-secrets.md](2026-06-20-pss-external-secrets.md)
  (PR #238). A high-quality independent writeup (files delivered table,
  exact securityContext shape applied, explicit note on why no `emptyDir`
  override was needed) — full content verified against the ROADMAP spec
  before trimming.

Each trimmed item's full inline text replaced with the established
short-pointer format. No information lost — the full detail already lived
in the linked `docs/done/` files, confirmed equivalent by reading all three
before editing.

## Result

`ROADMAP.md`: 2420 → 2371 lines (49 lines saved from 3 items — a larger
per-item saving than recent batches, since these three carried their full
original executor specs rather than already-shortened prose). ~151 legacy
items remain for future bounded cycles to continue against.

No `gitops/` change. `make ci` fully clean (exit 0, zero `not ok` lines).

## PR

https://github.com/tooming/k8s-anywhere/pull/1495 (chore/roadmap-legacy-item-trim-batch7)
