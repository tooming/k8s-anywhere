# docs/dependency-register.md — correct the stale summary date + name the no-ADR observability gap

Executor filler item (ROADMAP rule #9 doc precision; executor.prompt.md STEP 6b
fallback chain — cycle 12, after the Now/next lane remained gated on #631/#633/#1034).

Two small, real fixes:

1. **Stale summary date.** The file's own "Keeping this in sync" section said "a
   manual, best-effort snapshot as of 2026-08-06" — but two rows in the table above
   it (ArgoCD, Trivy Operator) were already updated to 2026-08-07 by earlier cycles
   in this same run. Corrected the summary line to match, rather than leave it one
   day behind the data it describes.

2. **Named a real coverage gap, honestly.** Checked directly (grepped
   `docs/decisions/*.md` for each name) that several real, always-on third-party
   dependencies have **no dedicated ADR at all** — GitLab (referenced by name across
   many ADRs, never itself the *subject* of one) and the observability pipeline's
   internals (Mimir, Loki, Tempo, Pyroscope, Alloy, kube-state-metrics,
   node-exporter — only Grafana, the pane-of-glass on top of all of them, has its
   own ADR-0006). This register's own construction rule cites the ADR that decided
   each row, so these tools structurally cannot appear in it — not this register's
   bug to fix (inventing an ADR-citation for content that doesn't exist would
   violate ADR-0004), but worth naming plainly in the Scope note rather than
   silently under-counting the lab's real third-party surface. Closing it (deciding
   whether each warrants a retroactive ADR, or one combined ADR for the LGTMP
   stack) is explicitly out of scope here — named as architect-scoped follow-up
   work, not built.

`make ci` passes, including `tests/dependency-register.bats`'s existing structural
assertions.

## PR

https://github.com/tooming/k8s-anywhere/pull/1071
