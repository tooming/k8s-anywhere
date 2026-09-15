# ROADMAP.md legacy `[x]` item trim — batch 9

STEP 6b JANITOR-fallback cleanup: the "Now / next" lane was empty (the one
🟢 item, Oracle Terraform-provider caching, was already implemented and
merged earlier this same run — PRs #1620/#1621), and the intake queue
(open issues) was empty too, so PLANNER's own gap-analysis lens found
nothing new to groom. CHARTER's two live Objectives (O2 default-deny +
PSS-restricted, O7 DORA metrics) both currently look on track (namespace
test coverage matches all 4 always-on namespaces; `docs/dora-metrics.md`
was refreshed the day before this run). Outbound network egress needed for
any further Terraform-provider/Helm-chart/GitHub-release currency check is
confirmed blocked from this sandbox (`registry.terraform.io` and
`api.github.com` both return `403`/`connect_rejected` through the agent
proxy) — the same environment limit prior `[Action needed]` cycles this
run already hit (see cycle 8's terraform-provider-bumps-blocked record).

Continuing batch 7 and batch 8
([docs/done/2026-09-08-roadmap-legacy-item-trim-batch7.md](2026-09-08-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-08-roadmap-legacy-item-trim-batch8.md](2026-09-08-roadmap-legacy-item-trim-batch8.md)),
which had already resolved every candidate their scan heuristic (a `[x]`
item with NO `docs/done/` link yet, carrying substantial inline
investigation prose) could find. Batch 8's own note named the next lens to
try: items that **already** cite a `docs/done/` link but still carry
substantial inline duplication alongside it — never yet attempted. This
batch is that lens.

## What was done

Wrote a small script walking `ROADMAP.md`'s `- [x]`/`- ~~` bullet items,
measuring each item's line span and flagging ones over ~12 lines that
already contain a `(docs/done/...)` reference. Read each flagged
candidate's full ROADMAP text side-by-side with its cited `docs/done/`
mirror before trimming — skipped one candidate (the GitLab→Forgejo rename
item) because its "closed as moot" note has no dedicated mirror of its own
(the `docs/done/` links inside its body are for a tangential fix, not the
item's own closure — same class of mistake batch 7 explicitly warned
against making). Trimmed 7 confirmed-safe candidates, each verified
word-for-word against a real, complete `docs/done/` mirror before cutting:

1. **`lab-demo` HotROD→hello-world image swap** →
   [docs/done/2026-09-08-lab-demo-hello-world-swap.md](2026-09-08-lab-demo-hello-world-swap.md)
   (73→5 lines).
2. **Fault-injection drill — ArgoCD** →
   [docs/done/2026-09-11-dr-chaos-argocd.md](2026-09-11-dr-chaos-argocd.md)
   (47→4 lines).
3. **Fault-injection drill — cert-manager** →
   [docs/done/2026-09-12-dr-chaos-cert-manager.md](2026-09-12-dr-chaos-cert-manager.md)
   (41→4 lines).
4. **Dead Harbor containerd registry-mirror cleanup** →
   [docs/done/2026-09-08-dead-harbor-registry-mirror-cleanup.md](2026-09-08-dead-harbor-registry-mirror-cleanup.md)
   (33→5 lines).
5. **`scripts/ensure-lint-tools-hook.sh`** →
   [docs/done/2026-09-06-ensure-lint-tools-session-start-hook.md](2026-09-06-ensure-lint-tools-session-start-hook.md)
   (33→5 lines).
6. **`scripts/ensure-manifest-tools-hook.sh`** →
   [docs/done/2026-09-06-ensure-manifest-tools-session-start-hook.md](2026-09-06-ensure-manifest-tools-session-start-hook.md)
   (34→5 lines).
7. **`scripts/ensure-yq-hook.sh`** →
   [docs/done/2026-09-06-ensure-yq-session-start-hook.md](2026-09-06-ensure-yq-session-start-hook.md)
   (33→4 lines).

No information lost — every trimmed item's full original text (rationale,
scope, and verification detail) already lives complete in its cited
`docs/done/` mirror; the ROADMAP.md copy was pure duplication.

## Result

`ROADMAP.md`: 2717 → 2480 lines (237 lines saved from 7 items). At least
one confirmed non-candidate remains deferred (the GitLab→Forgejo rename
item, `- [x]` at what is now ~line 950 — genuinely needs its own careful
read to identify the right mirror, or may need to stay inline since its
closure has no single clean mirror at all) — a future cycle with more
budget to spend on that one specific item can pick it up. The
already-`docs/done/`-linked-but-still-duplicated lens this batch used is
otherwise not yet exhausted across the rest of the file — a future JANITOR
cycle can keep running the same scan.

## Validation

`make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green). `make roadmap-check` and
`make markdown-links-check` — clean.

No `gitops/` change.

## PR

#1622
