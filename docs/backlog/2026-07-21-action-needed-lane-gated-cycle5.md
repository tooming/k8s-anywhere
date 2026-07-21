# [Action needed] Now/next still fully gated; three more fresh lenses came up empty

## What's blocked

Unchanged from this run's prior cycles: the five remaining `[ ]` items in
ROADMAP.md's *Now / next* are all gated on a maintainer-confirmation
prerequisite this remote clusterless session cannot satisfy — issues
#631/#632/#633 (re-verified this cycle: still open, still zero comments).

## What this run has done across 5 cycles (3 real PRs, 1 labeling pass)

- **Cycle 1 (upgrade-drafter):** RabbitMQ `4.3.2-management` → `4.3.3-management`
  (**PR #636**), surfaced by a fresh 19-component ADR-pinned upstream-release
  sweep (architect lens).
- **Cycle 2 (triager):** labeled all three standing `[Action required]`
  issues (`domain:*`, `readiness:green`, `priority:p1`).
- **Cycle 3 (janitor):** a mechanical recurrence guard,
  `scripts/adr-image-pin-sync-check.sh`, for the exact ADR-drift class PR
  #636's own diff exposed a hole in (**PR #637**).
- **Cycle 4:** a fresh non-ADR image-tag sweep (redis_exporter, kafka, moto,
  vault-unsealer, garage, loki, mimir, tempo) found nothing further to bump
  — recorded as **PR #638**.

## This cycle's sweep (three new lenses, all came up empty)

1. **ADR flip-condition re-scan.** Grepped every `**Flip condition**` /
   `**Flip conditions**` block across all 15 ADRs that have one
   (ADR-0006, 0008, 0009, 0012, 0013, 0016, 0017, 0018, 0019, 0020, 0023,
   0028). None are met: Longhorn's is an EOL-window/CVE trigger (current
   `1.11.3` is not EOL, `1.12.1-rc1` is a pre-release, not a stable trigger);
   the rest are new-bulletin/new-CVE triggers, none fired since the last
   check.
2. **Whole-repo TODO/FIXME/XXX grep** (not just `scripts/`/`gitops/`, which
   prior cycles already covered — this pass widened to `infra/`, `docs/`,
   and root-level files). Found exactly one real, non-historical TODO:
   `infra/modules/argocd/values.yaml`'s `global.image.tag: latest` override,
   with an explicit removal condition ("drop this override once argo-cd
   chart >= the version that ships the expose-appset-ui commit #26666").
3. **Investigated that TODO directly.** Confirmed PR #26666
   ("expose Appset UI") merged to `argoproj/argo-cd` `master`, but has only
   shipped in the `v3.5.0-rc1`/`rc2` pre-release line — **no stable GA
   release contains it yet**, and no `argo-helm/argo-cd` chart version up to
   `10.1.4` (checked `Chart.yaml` directly) defaults to an `appVersion` that
   would include it (`10.1.4`'s `appVersion` is still `v3.4.5`). The
   `image.tag: latest` override is genuinely still required — not stale,
   correctly left alone. This is exactly the "coverage/hardening sweep" ROADMAP
   rule #9 describes; it earned a "no action needed, confirmed correct"
   verdict rather than a code change, which is itself a legitimate outcome.

## What would unblock further work

Unchanged: (a) the maintainer confirming a live-cluster observation on
#631/#632/#633; (b) a new upstream CVE/release firing one of the 15 ADRs'
flip conditions (none found this cycle); (c) `argo-cd v3.5.0` reaching GA
(currently `rc2`) and an `argo-helm` chart bump adopting it, which would let
a future run drop the ArgoCD `image.tag: latest` override for a normal
pinned chart bump; (d) a new GitHub issue of any size.

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
