# Planner note — 2026-08-06 (Grafana `13.0.3` → `13.0.5` + Tempo ADR log-drift correction)

## What this run did

Reached the planner role via `executor.prompt.md` STEP 6b for the second time
this run (first pass grafana/loki 3.7.5→3.7.6, PR #1041/#1042, already
merged). All three standing "Now / next" items were re-confirmed still gated
on maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) — no change since
the last check this run. No ungroomed GitHub issues existed to groom.
`docs/roadmap/incoming/` held no pending architect items. No later ROADMAP
section held an un-promoted 🟢 item.

Per `executor.prompt.md` STEP 8's "widen the lens" guidance — don't repeat
the identical search a prior cycle this same run already ran — this pass
deliberately looked at a **different set** of GitHub-hosted `image:` pins
than the immediately-prior Loki-only cycle: Mimir, Grafana's `image.tag`
override, RabbitMQ, and Valkey.

## What was found

- **Mimir** (`3.1.4` pinned): `git ls-remote --tags grafana/mimir` shows
  `mimir-3.1.4` is still the newest tag on the `3.1.x` line. No gap.
- **RabbitMQ** (`4.3.4-management` pinned, ADR-0009-tracked): `git ls-remote
  --tags rabbitmq/rabbitmq-server` shows `v4.3.4` is still the newest tag on
  the `4.3.x` line. No gap (also confirmed by `make ci`'s own
  `adr-image-pin-sync-check`, which stayed green).
- **Valkey** (`8.0.10-alpine` pinned, ADR-0018-tracked): `git ls-remote --tags
  valkey-io/valkey` shows `8.0.10` is still the newest tag on the `8.0.x`
  line (a `9.x` line exists but that's a major bump needing an architect
  RFC, out of scope here). No gap.
- **Grafana image tag** (`13.0.3` pinned, tracked separately from the chart's
  own `targetRevision` per ADR-0006's CVE-driven analysis): one real,
  verified gap. `git ls-remote --tags grafana/grafana` shows `v13.0.5` as the
  newest tag on the `13.0.x` line. `git log v13.0.3..v13.0.5 --no-merges`
  contains an explicitly `Security:`-tagged commit fixing GHSA-mpwr-8vm7-h73f
  (a PKCS#12 password-bypass vulnerability in `go-pkcs12`, pulled in
  transitively via `grafana-azure-sdk-go`) — satisfies ADR-0006's own flip
  condition the same way the 2026-07-19 CVE bump did. `git diff v13.0.3
  v13.0.5 -- packaging/docker/` is empty, so the existing packaging/
  read-only-root-filesystem analysis in `observability-grafana.yaml`'s
  comments carries forward unchanged — re-verified, not assumed.

While re-checking Tempo as part of this same sweep (to see if its own pin
needed a bump), found the pin itself needs no change (`2.10.7` is already the
newest `2.10.x` tag), but ADR-0006's last two dated log entries still cite
`2.10.5` — a log-drift gap of the exact same shape the 2026-08-06 Loki entry
caught for its own pin (an earlier, undocumented bump that never got a
matching log update). Folded the correction into this same ROADMAP item
since both are ADR-0006 `## Re-evaluation log` edits for the same LGTMP-stack
audit, rather than spinning up a second near-empty item just to keep them
separate.

Added as a new 🟢 Now/next item (`auto/grafana-image-13-0-5`) with full
implementation detail.

## Why no other action this cycle

The sweep found one real, CVE-verified image-tag gap (Grafana) plus one
real, verified log-accuracy gap (Tempo, no code change) — bundled into a
single well-scoped item, this cycle's honest deliverable. Mimir/RabbitMQ/
Valkey were all confirmed already current, closing out this pass's angle
cleanly.

## What would unblock further Now/next work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub issue
of any size; (c) the still-open ArgoCD Terraform-chart `10.2.2`→`10.2.3`
(appVersion `v3.4.6`→`v3.5.0`) diligence flagged by the 2026-08-05 planner
note (unresolved, not re-attempted this cycle); (d) the Grafana chart's own
`13.0.x`→`13.1.x` minor-line jump (available upstream but deliberately not
bundled here — needs its own deeper diligence pass per ADR-0006's established
bar for anything beyond a same-line patch).

This is this cycle's deliverable, not the run's stopping point — the run
continues per `executor.prompt.md` STEP 8, which should pick up the
newly-added Grafana item directly.
