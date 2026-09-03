# ROADMAP.md legacy `[x]` item trim — pilot batch (RFC #377 Oracle items)

`ROADMAP.md`'s own "Investigation-note discipline" note (2026-08-25) named
this exact class of cleanup: "the ~180 already-completed `[x]` items' own
inline writeups are a separate, larger cleanup (each needs verifying against
its `docs/done/` mirror before trimming) intentionally left for a future
bounded cycle, not attempted in this one." Ten days later, with the file even
larger (7382 lines at this cycle's start), this cycle picks up a small,
verified pilot batch.

## What was done

Trimmed the four RFC #377 (Oracle cloud backend) items — each already had a
genuine, real `docs/done/` mirror with a real PR link, verified by reading
all four files before touching the ROADMAP text:

- `infra/modules/oracle-k3s-cluster` Terraform module →
  [docs/done/2026-07-13-oracle-k3s-cluster-module.md](2026-07-13-oracle-k3s-cluster-module.md)
  (PR #379)
- `infra/live/oracle/{cluster,argocd,gitlab}/terragrunt.hcl` →
  [docs/done/2026-07-13-oracle-live-units.md](2026-07-13-oracle-live-units.md)
  (PR #382)
- Second off-cluster Garage state store for `oracle` →
  [docs/done/2026-07-13-oracle-tfstate.md](2026-07-13-oracle-tfstate.md)
  (PR #381)
- `tests/oracle-cluster.bats` →
  [docs/done/2026-07-13-oracle-cluster-bats.md](2026-07-13-oracle-cluster-bats.md)
  (PR #383)

Each item's full multi-paragraph inline text (~50 lines total) replaced with
the established short-pointer format: title, `docs/done/` link, branch name —
matching how every item this run has authored already looks. No information
lost — the full detail lives in the linked `docs/done/` files, byte-for-byte
what the inline text described.

## Result

`ROADMAP.md`: 7382 → 7351 lines (31 lines saved from 4 items). Small on its
own, but establishes the verified pattern (read the docs/done mirror, confirm
it's a genuine match, then trim) for a future cycle to continue against the
remaining ~176 items — deliberately bounded to a small, fully-verified batch
this cycle rather than attempting the whole backlog at once (WAYS-OF-WORKING
§3's per-PR size discipline).

No `gitops/` change. `make ci` passes green (2976/2976 bats tests, shellcheck
and yamllint both installed and run clean for this cycle's own verification).

## PR

(filled in after PR creation)
