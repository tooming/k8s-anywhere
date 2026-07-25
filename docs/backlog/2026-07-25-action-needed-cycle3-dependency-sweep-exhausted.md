# [Action needed] Now/next still gated; this run already shipped 2 real dependency bumps, fresh sweep also came up clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (third cycle of 2026-07-25): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC. No new GitHub issues exist
beyond these three standing trackers, and `docs/roadmap/incoming/` is empty
(no pending architect items to absorb).

## This run's real progress (not idle)

This run already shipped two real, merged upgrade PRs before this cycle's
note:

- **PR #718** (`upgrade/kargo-chart-1-10-9-to-1-11-0`) — Kargo Helm chart
  `1.10.9` → `1.11.0`. Verified via the OCI registry's paginated tag list
  (the default unpaginated response silently truncates — a real footgun) and
  schema-diffed the chart's committed `values.yaml` at both git tags. Also
  corrected ADR-0023's stale "Chart + version" block (six bumps out of date).
- **PR #719** (`upgrade/redis-exporter-1-87-0-to-1-88-0`) — the Valkey
  sidecar's `redis_exporter` image `v1.87.0-alpine` → `v1.88.0-alpine`.
  Verified via the source repo's git tags, cross-checked the exact `-alpine`
  variant exists on Docker Hub (not just the bare tag).

## This cycle's fresh angle (came up empty, but real)

After shipping the above, walked the full fallback chain again from the top
looking for a third deliverable:

1. **Planner lens** — no open issues beyond the three standing trackers, no
   `docs/roadmap/incoming/` files to absorb. Nothing to groom.
2. **Architect lens** — every 🟡 item in ROADMAP.md's "Cross-cutting
   hardening & quality" section is either already RFC'd/decided (struck
   through) or checked off. No un-RFC'd 🟡 item exists to write an RFC for.
3. **Upgrade-drafter lens (extended)** — re-swept every remaining
   Docker-Hub/GHCR-hosted image tag not yet covered by today's or
   yesterday's cycles: `curlimages/curl` (8.21.0, current), `danielqsj/
   kafka-exporter` (v1.9.0, current), `motoserver/moto` (5.2.2, current),
   `grafana/mimir` (3.1.4, current), `grafana/tempo` (2.10.7, current on the
   2.x line — 3.0.x exists but is a major bump, out of upgrade-drafter's
   scope), `dxflrs/garage` (v2.3.0, confirmed via the `deuxfleurs-org/garage`
   GitHub mirror since the primary `git.deuxfleurs.fr` host is
   proxy-blocked, current). Also re-verified the Grafana Helm chart pin
   (`12.8.0`) directly against the real `grafana-community/helm-charts` git
   tags (the actual current chart source — distinct from the archived
   `grafana/helm-charts` repo, whose lookalike `alloy-*` tags turned out to
   be a red herring with no corresponding chart content, caught and
   discarded mid-investigation rather than acted on) — confirmed current,
   no gap. The Alloy and Pyroscope chart versions remain genuinely
   unverifiable in this sandbox (their real publish index is a
   `*.github.io` Pages host, proxy-blocked here, and no reliable git-tag
   correlation exists) — left untouched rather than guessed at, per
   ADR-0004.
4. **Doc-drift-author lens** — `make ci`'s `readme-check` and `lab-ui-check`
   both passed clean with no drift warnings. Manually scanned every
   `gitops/platform/*.yaml` Application for a `path:` referencing a
   nonexistent directory — the only two hits
   (`gitops/platform/governance-appset.yaml`/`networkpolicy-appset.yaml`'s
   `{{gitPath}}` ApplicationSet template placeholder, and
   `observability-grafana.yaml`'s in-pod mount path
   `/var/lib/grafana/dashboards/community`) are both expected, not drift.
5. **Triager lens** — all three open issues already carry full labels
   (`priority:p1`, a `domain:*` label, `readiness:green`). Nothing
   untriaged.
6. **Janitor lens** — swept every `scripts/*.sh` for zero references
   anywhere (none found — full coverage, matching yesterday's cycle-1
   finding) and for no bats test referencing it (none found either).
   Grepped `gitops/`, `scripts/` for `TODO`/`FIXME`/`XXX:` markers — zero
   hits. No unbounded monolith or duplication candidate identified that
   would land as a clean, single-sitting cleanup.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size; (d) a reliable way to verify Grafana Alloy/Pyroscope chart
versions in this sandbox (currently blocked by proxy restrictions on their
publish host).

This note is this cycle's honest record — on top of two merged PRs (#718,
#719) earlier in this same run — not a stopping point. The run continues to
the next cycle per `executor.prompt.md` STEP 8.
