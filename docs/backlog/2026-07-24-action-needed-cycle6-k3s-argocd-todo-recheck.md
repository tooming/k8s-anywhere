# [Action needed] Now/next still gated; k3s pin + ArgoCD `latest` TODO re-checked, both correctly held

## What's blocked

The "Now / next" lane's remaining unchecked items are all gated on the standing
maintainer-confirmation issues #631/#632/#633 — re-verified this cycle (tenth cycle
of this run, sixth dated cycle today): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC.

## This cycle's fresh angle

Two checks not covered by any prior cycle today:

1. **k3s version currency (ADR-0030).** `infra/modules/oracle-k3s-cluster/
   cloud-init.yaml` and `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` both pin
   `v1.36.2+k3s1`/`v1.36.2-k3s1`. `git ls-remote --tags
   https://github.com/k3s-io/k3s.git` confirms `v1.36.2+k3s1` is still the newest
   tag on the `1.36.x` line (and overall) — no gap.
2. **The `infra/modules/argocd/values.yaml` `image.tag: latest` TODO,
   re-verified against real upstream state.** The comment says this override
   exists to get the `/applicationsets` UI route from commit
   `argoproj/argo-cd#26666` ("expose Appset UI and fix pie chart summary"),
   "merged post-v3.4.3, not yet in a stable release" — re-checked directly: cloned
   `argoproj/argo-cd` and confirmed the commit (`4d02fc2f5`) is genuinely **not**
   an ancestor of `v3.4.5` (the newest `3.4.x` patch) and only appears from
   `v3.5.0-rc1` onward — still a pre-release, no stable `v3.5.0` has shipped. The
   `latest` pin is still correctly necessary; nothing to drop yet. (Also grepped
   the whole `gitops/`/`scripts/`/`infra/` tree for other `TODO`/`FIXME`/`XXX:`
   markers — this is the only one that exists in non-doc code.)

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked flip condition; (c) a new GitHub issue of any size;
(d) `argo-cd` cutting a stable `v3.5.0`+ release (would let the ArgoCD `latest`
image-tag override in `infra/modules/argocd/values.yaml` be dropped in favor of a
pinned version — worth a fresh check next sweep).

This note is this cycle's honest record — on top of the eight PRs already merged
earlier in this same run (#701, #702, #703, #706, #709, #710, #711, plus this
lane-gated note's own predecessor #712) — not a stopping point. The run continues
to the next cycle per `executor.prompt.md` STEP 8.
