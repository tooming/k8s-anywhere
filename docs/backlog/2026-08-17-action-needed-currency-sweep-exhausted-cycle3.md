# [Action needed] Now/next still gated; currency sweep exhausted, three findings need live-cluster follow-up

**Date:** 2026-08-17
**Cycle:** 3rd cycle this run (after PR #1203 — ACK s3-controller chart bump,
PR #1204 — kube-state-metrics chart bump)

## What's blocked

The "Now / next" lane holds six unchecked items, all still gated:

1. **Flip `Application` `repoURL`s to the Forgejo remote** — explicit
   live-cluster-only flip. **Note:** a concurrent interactive session opened
   [PR #1205](https://github.com/tooming/k8s-anywhere/pull/1205)
   (`chore/gitlab-to-forgejo-cutover`) during this run doing exactly this, live,
   per explicit maintainer direction — this cycle deliberately did not touch
   anything Forgejo/GitLab-related to avoid conflicting with that in-flight work.
2. **Rename `scripts/gitlab-*.sh` → `forgejo-*.sh`** — sequentially blocked on
   item 1 (PR #1205, once merged, satisfies the prerequisite but the rename
   itself is still separate follow-up work per that PR's own body).
3. **Decommission `gitlab/docker-compose.yml`** — sequentially blocked on
   items 1–2.
4. **`verifyImages` ClusterPolicy Audit → Enforce flip** — gated on standing
   issue [#631](https://github.com/tooming/k8s-anywhere/issues/631) (re-checked
   this cycle: still open, still chasing a live signed-image confirmation; PR
   #1205's own body confirms this verification is "still outstanding").
5. **O4 CI gate — `verify-image-rejection` job** — sequentially blocked on
   item 4.
6. **Remove legacy capstone `Deployment`** — gated on standing issue
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-checked this
   cycle: still open; its latest comment found a *new* prerequisite gap, the
   `argo-rollouts` Application itself failing to sync since 2026-08-11).

## What was tried this cycle (STEP 6b fallback chain, in order)

- **PLANNER**: no groomable intake — the only two open issues are #631/#633,
  both correctly-labeled standing trackers, not user work requests. No
  un-RFC'd 🟡 item anywhere in ROADMAP.md (verified: zero `- [ ] 🟡` lines). No
  `docs/roadmap/incoming/` file to absorb (dir holds only its `README.md`).
- **ARCHITECT**: no un-RFC'd 🟡 item to decide (same finding as above).
- **UPGRADE-DRAFTER**: this run's real deliverable so far — an exhaustive
  upstream-currency sweep across ~30 pinned sources found two genuine gaps,
  both shipped as their own PRs this run: ACK s3-controller chart `1.9.0` →
  `1.10.0` ([#1203](https://github.com/tooming/k8s-anywhere/pull/1203),
  merged) and kube-state-metrics chart `8.3.0` → `8.3.1`
  ([#1204](https://github.com/tooming/k8s-anywhere/pull/1204), merged). Every
  other checked source confirmed current (Forgejo, Forgejo-runner, RabbitMQ,
  k3s, Vault, external-secrets, kro, Longhorn — correctly held per ADR-0013's
  flip condition, Garage, Kyverno, Istio, Velero, Kiali, Trivy Operator,
  cert-manager, KEDA, Cilium, Argo Rollouts, TiDB Operator, node-exporter,
  Harbor, Loki, actions/checkout, hashicorp/setup-terraform, actions/cache,
  actions/github-script) or is a deliberate ADR-governed hold whose flip
  condition hasn't fired (TiDB, Valkey already bumped this run's earlier
  cycles).

  **Three real findings deliberately deferred, not blind-bumped, this cycle:**
  1. **Envoy Gateway `v1.8.3` → `v1.9.0`** (went stable 2026-08-15). It's this
     lab's sync-wave-0, always-on-core north-south ingress control plane
     (ADR-0008) — every HTTPRoute in the cluster depends on it. The fetched
     changelog describes multiple breaking changes, including a Gateway API
     CRD version requirement, and this remote clusterless session has no
     `helm`/`kubeconform`-against-live-CRDs way to verify a bump this critical
     renders cleanly before a live ArgoCD sync applies it fleet-wide.
  2. **Grafana image `13.0.5` → `13.0.6`** (real tag, released 2026-08-07).
     Could not obtain a clear description of what changed — the upstream
     `CHANGELOG.md`'s `13.0.5` section is empty of bullets, and no security
     advisory specific to `13.0.6` was found. Grafana is always-on-core and
     user-facing; bumping without understanding the delta would violate this
     session's own verify-before-asserting bar (ADR-0004).
  3. **`.forgejo/workflows/build-sign-push.yml`'s `actions/checkout@v4`** is
     the only action reference in the repo not SHA-pinned (every
     `.github/workflows/*.yml` action is). This looked like a JANITOR-style
     consistency gap at first glance, but the file's own header comment
     already flags it as an *open, deliberate* question: "`actions/checkout@v4`
     resolves the way Forgejo's default actions-proxy expects" is listed as
     one of three mechanics this clusterless session's original authoring pass
     could not verify and left for a live Forgejo-runner session to confirm —
     changing the pin form here without that live verification risks silently
     breaking the one CI path PR #1205's cutover now depends on.

  Each finding is real and actionable, but every one needs either live-cluster
  verification (Envoy Gateway, checkout@v4) or clearer upstream changelog
  content (Grafana) before an executor should act on it — not a reason to
  force a bump through without verification (ADR-0004), and not the "nothing
  found" case Rule #9 describes.
- **DOC-DRIFT-AUTHOR**: `make ci`'s `readme-check` + `lab-ui-check` both clean.
  No broken Application source paths found.
- **TRIAGER**: both open issues (#631, #633) already carry `domain:*` +
  `readiness:*` + `priority:*` labels — nothing untriaged.
- **JANITOR**: the one candidate found this cycle (`actions/checkout@v4` above)
  turned out to be an already-documented open question, not an oversight — see
  above. No other genuine duplication/dead-code/missing-guard candidate found
  this cycle (checked: no `TODO`/`FIXME`/`XXX:` markers anywhere in
  `scripts/*.sh` or `gitops/`; the bats-coverage sweep that found and fixed
  `forgejo-runner-ensure.sh`'s gap earlier this run already covers every
  `scripts/*.sh` file). Deliberately avoided any GitLab/Forgejo-scoped cleanup
  this cycle to not conflict with PR #1205's in-flight live cutover.

## What would unblock the gated items

- **#631 / #633**: a live-cluster session observing (a) a real signed image
  landing in Harbor via CI, and (b) a real Kargo promotion completing —
  neither is possible from this remote clusterless session. PR #1205's merge
  (once it lands) will change the git-source-of-truth picture materially, but
  neither standing issue's own ask is satisfied by that PR alone per its own
  body text.
- **Envoy Gateway / Grafana / checkout@v4 findings above**: a live-cluster or
  better-tooled (`helm` available) session to verify each before acting.

This cycle's honest deliverable is this record — the fallback chain was walked
in full and yielded no further clean, verifiable, same-cycle-landable item
beyond what's already shipped (PRs #1203, #1204). Going straight back to
STEP 1 per STEP 8 — this is not a stopping point.
