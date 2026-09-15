# ROADMAP.md legacy `[x]` item trim — batch 10

Continuing batch 9
([docs/done/2026-09-15-roadmap-legacy-item-trim-batch9.md](2026-09-15-roadmap-legacy-item-trim-batch9.md)),
same run, next cycle: the "Now / next" lane and intake queue were both
still empty (batch 9's own PR was this run's most recent merge), and
batch 9's own note said its lens — `[x]` items that already cite a
`docs/done/` link but still carry substantial duplicated inline text — was
"not yet exhausted across the rest of the file." Re-ran the same scan
script against the post-batch-9 `ROADMAP.md` and found 18 more candidates
over ~12 lines.

## What was done

Read each flagged candidate's full text against its cited `docs/done/`
mirror before trimming (same discipline as batch 9 — skip anything whose
closure doesn't have one single clean mirror). Trimmed 6 confirmed-safe
items (156 lines saved):

1. **`docs/DR.md` "truly start over" `colima delete --data` note** →
   [docs/done/2026-09-08-dr-md-colima-delete-data-note.md](2026-09-08-dr-md-colima-delete-data-note.md)
   (32→4 lines).
2. **`scripts/dependency-maintenance-check.sh` stale header counts** →
   [docs/done/2026-09-08-dependency-maintenance-check-stale-counts-cleanup.md](2026-09-08-dependency-maintenance-check-stale-counts-cleanup.md)
   (32→4 lines).
3. **Terraform `1.15.9`→`1.16.1` / Terragrunt `v1.1.3`→`v1.1.4` bump** →
   [docs/done/2026-09-06-terraform-terragrunt-currency-bump.md](2026-09-06-terraform-terragrunt-currency-bump.md)
   (32→4 lines).
4. **`scripts/coredns-host-alias.sh` header + docs Forgejo-era note** →
   [docs/done/2026-09-08-coredns-host-alias-forgejo-note-cleanup.md](2026-09-08-coredns-host-alias-forgejo-note-cleanup.md)
   (31→5 lines). Kept the issue #1517 cross-reference in the trimmed text
   (it independently closed via PR #1542 during this same run's history —
   confirmed live via `issue_read` before trimming — so the note now
   correctly reads as historical rather than open-ended).
5. **`scripts/ensure-bats-hook.sh`** →
   [docs/done/2026-09-06-ensure-bats-session-start-hook.md](2026-09-06-ensure-bats-session-start-hook.md)
   (31→4 lines).
6. **ADR-0016/ADR-0017 stale `vault`/`external-secrets`/etc. namespace
   references** →
   [docs/done/2026-09-08-adr-0016-0017-stale-namespace-refs-cleanup.md](2026-09-08-adr-0016-0017-stale-namespace-refs-cleanup.md)
   (30→4 lines).

No information lost — every trimmed item's full rationale/scope/
verification detail already lives complete in its cited mirror.

## Result

`ROADMAP.md`: 2480 → 2324 lines (156 lines saved from 6 items). The
GitLab→Forgejo rename item (still `- [x]` with no single clean mirror,
same one batch 9 deferred) remains untrimmed. Re-running the same scan
script after this batch still finds more candidates over the ~12-line
threshold — this lens is a big, multi-batch job, not a one-cycle
cleanup; a future JANITOR cycle can keep going the same way.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green). `make roadmap-check` and
`make markdown-links-check` — clean.

No `gitops/` change.

## PR

#1623
