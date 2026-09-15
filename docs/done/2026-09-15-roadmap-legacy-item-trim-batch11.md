# ROADMAP.md legacy `[x]` item trim — batch 11

Continuing batch 9/10
([docs/done/2026-09-15-roadmap-legacy-item-trim-batch9.md](2026-09-15-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-15-roadmap-legacy-item-trim-batch10.md](2026-09-15-roadmap-legacy-item-trim-batch10.md)),
same run, next cycle: lane and intake queue both still empty. Re-ran the
same scan script against the post-batch-10 `ROADMAP.md` and found 12 more
candidates over ~12 lines.

## What was done

Same discipline as batches 9/10 — read each candidate's full text against
its cited `docs/done/` mirror before trimming. Trimmed 6 confirmed-safe
items (122 lines saved):

1. **Fault-injection drill — Traefik** →
   [docs/done/2026-09-12-dr-chaos-traefik.md](2026-09-12-dr-chaos-traefik.md)
   (23→4 lines).
2. **Fault-injection drill — `lab-demo`** →
   [docs/done/2026-09-12-dr-chaos-lab-demo.md](2026-09-12-dr-chaos-lab-demo.md)
   (26→4 lines).
3. **`docs/dora-audit-readiness.md` Q15 stale "~30-repo sweep" claim** →
   [docs/done/2026-09-08-dora-audit-readiness-30-repo-note-cleanup.md](2026-09-08-dora-audit-readiness-30-repo-note-cleanup.md)
   (22→4 lines).
4. **Traefik full GHSA sweep** →
   [docs/done/2026-09-06-traefik-full-ghsa-sweep.md](2026-09-06-traefik-full-ghsa-sweep.md)
   (27→4 lines).
5. **Stale RabbitMQ/Valkey/KEDA `gitops/` header-comment references** →
   [docs/done/2026-09-06-rabbitmq-valkey-keda-comment-sweep.md](2026-09-06-rabbitmq-valkey-keda-comment-sweep.md)
   (25→4 lines).
6. **`docs/dora-audit-readiness.md` Kyverno `failurePolicy` ADR-0004 fix** →
   [docs/done/2026-09-06-dora-kyverno-failurepolicy-fix.md](2026-09-06-dora-kyverno-failurepolicy-fix.md)
   (24→4 lines).

No information lost — every trimmed item's full text already lives
complete in its cited mirror.

## Result

`ROADMAP.md`: 2324 → 2202 lines (122 lines saved from 6 items). The
GitLab→Forgejo rename item remains untrimmed (same deferral as batches
9/10 — no single clean mirror). Re-running the scan after this batch
still finds a handful more candidates just above/below the ~12-line
threshold — this multi-batch cleanup is close to exhausted for items
comfortably over the threshold, but not entirely done.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines. `make
roadmap-check` and `make markdown-links-check` — clean.

No `gitops/` change.

## PR

(filled in after PR creation)
