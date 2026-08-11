# Industry digest — week 2026-W33

_Period: 2026-08-10 – 2026-08-16. Fetched and written 2026-08-10 (architect-fallback
cycle, `executor.prompt.md` STEP 6b, fourth cycle this run — after two currency-bump
cycles (`auto/external-secrets-chart-2-9-0`, `auto/pyroscope-chart-2-2-1`) and one
planner-fallback grooming cycle (`plan/alerting-rfc-gap`) already shipped, and the
three standing Now/next items were re-checked and found still gated on
#631/#633/#1034)._

---

## At-a-glance

- **Two real currency gaps found and shipped earlier this run**: External Secrets
  Operator `2.8.0`→`2.9.0` (real CVE fixes — GHSA-hrxh-6v49-42gf, CVE-2026-56852) and
  Pyroscope `2.2.0`→`2.2.1` (upstream-declared **security release** — GHSA-r277-6w6q-xmqw,
  GHSA-hrxh-6v49-42gf, CVE-2026-56852, CVE-2026-46600). Both merged (#1081, #1082)
  before this digest was written — see `docs/done/2026-08-10-*.md` for the full
  writeups.
- **A very broad currency sweep this run** (20+ components, spanning both prior
  currency cycles and this digest's own fetch pass) found every other pinned chart/
  image current: cilium, argo-rollouts, harbor, istio, kro, longhorn, cert-manager,
  keda, vault, ack-s3, kargo, envoy-gateway, node-exporter, alloy, mimir, tempo,
  rabbitmq, valkey, k3s, gitlab-ce, gitlab-runner, kyverno, trivy (scanner + operator),
  argocd (chart + binary).
- **One trivial, non-security patch found but not chased**: Grafana `13.0.5`→`13.0.6`
  (released 2026-08-07) is a single-commit backport ("Snapshots: Backport of deletekey
  fix into 13.0.6") — a dashboard-snapshot bugfix this lab doesn't use, not a security
  fix. Doesn't meet the "ships with a real security fix" bar this lab's other
  non-major bumps use; left for a future sweep rather than bumped reflexively.
- **New RFC opened this cycle**: Grafana Unified Alerting for known failure
  conditions, closing `docs/dora-audit-readiness.md`'s Q7 gap ("no alerting"). See
  "For the architect" below — no new ADR needed, this uses only already-adopted
  components (Grafana's own Alerting engine, already-scraped Mimir metrics).
- **Garage** (`deuxfleurs/garage`) fetch not re-attempted this pass — its releases live
  on a self-hosted Gitea (`git.deuxfleurs.fr`), unreachable through this session's
  egress proxy (`CONNECT tunnel failed, response 403`), same block as prior runs
  reported. Relying on the last real audit (2026-07-28, `v2.3.0` kept, ADR-0002).

---

## Lab stack

### External Secrets Operator — `external-secrets/external-secrets` — chart bumped `2.8.0` → `2.9.0` (real CVE fixes)

Already covered in full in `docs/done/2026-08-10-external-secrets-chart-2-9-0.md` and
merged as #1081 earlier this run. `helm-chart-2.9.0` is the newest chart tag; both
`version`/`appVersion` moved. Real fixes: `grpc-go` (GHSA-hrxh-6v49-42gf),
`golang.org/x/text` (CVE-2026-56852). Diff otherwise purely additive (two new optional
pod-scheduling fields, a cert-controller cache-scoping toggle). Source:
<https://github.com/external-secrets/external-secrets/releases> (fetched 2026-08-10).

### Pyroscope — `grafana/pyroscope` — chart bumped `2.2.0` → `2.2.1` (upstream security release)

Already covered in full in `docs/done/2026-08-10-pyroscope-chart-2-2-1.md` and merged
as #1082 earlier this run. Notable finding: Pyroscope's chart source moved out of the
shared `grafana/helm-charts` monorepo into its own repo
(`grafana/pyroscope/operations/pyroscope/helm/pyroscope`) at some point since this
lab's chart was first pinned — worth remembering for any future Pyroscope currency
check (don't assume `grafana/helm-charts` is still authoritative for this chart).
Upstream PR (grafana/pyroscope#5474) states explicitly this release "aligns with the
v2.2.1 **security release** of Pyroscope" — four real CVE fixes (GHSA-r277-6w6q-xmqw
critical, GHSA-hrxh-6v49-42gf, CVE-2026-56852, CVE-2026-46600). Source:
<https://github.com/grafana/pyroscope/releases> (fetched 2026-08-10).

### Grafana image tag — `grafana/grafana` — pin `13.0.5`, one trivial patch available, not bumped

`git ls-remote --tags grafana/grafana` shows `v13.0.6` (published 2026-08-07,
03:06 UTC) as the newest `13.0.x` tag, one patch past this lab's pin. A real clone's
`git log v13.0.5..v13.0.6` contains exactly one commit: "Snapshots: Backport of
deletekey fix into 13.0.6" (#130315) — a bugfix for deleting dashboard snapshots, a
Grafana feature this lab's `gitops/platform/observability-grafana.yaml` doesn't
configure or rely on (no snapshot-related `valuesObject` keys). No `Security:` tag, no
CVE. This doesn't meet the "ships with a real security fix" bar this lab's other
non-major currency bumps use (see the ESO/Pyroscope entries above, both of which did)
— not bumped this cycle. Flip condition: bump when a future patch on the `13.0.x`
line carries a real fix (security or otherwise functionally relevant to this lab's
config), same standard as every other tracked pin.

Source: <https://github.com/grafana/grafana/releases> (fetched 2026-08-10).

### Everything else pinned in `gitops/platform/` and `infra/` — reconfirmed current

This run's own three prior cycles (two currency-bump PRs + this digest's own fetch
pass) directly verified each of these against real upstream tags:
**cilium** `1.18.12` (newest `1.18.x`, matches ADR-0014's hold), **argo-rollouts
chart** `2.41.1` (newest `argo-rollouts-2.x` tag), **harbor chart** `1.19.2` (newest
`v1.19.x` tag), **istio** (base/cni/istiod) `1.30.3` (newest stable `1.30.x`), **kro**
`0.9.3` (newest `v0.9.x`), **longhorn** `1.11.3` (the apparent `v1.11.4` tag is a
`-dev-*` prerelease only — no real `v1.11.4` release exists yet, confirmed by checking
the raw tag list rather than a truncated regex match), **cert-manager** `1.21.1`
(newest `v1.21.x`), **keda** `2.20.2` (newest `v2.20.x`, chart repo re-tagged from the
old `vX.Y.Z` scheme), **vault-helm** `0.34.0` (newest `v0.34.x`), **ack-s3** `1.9.0`
(newest `v1.9.x`), **kargo chart** `1.11.0` (newest, `akuity/kargo` tags), **envoy
gateway** `v1.8.3` (newest, no RC), **node-exporter chart** `4.56.1` (newest
`prometheus-node-exporter-4.56.x`), **alloy chart** `1.11.1` (newest `alloy-1.11.x`
in `grafana/helm-charts` — the app repo `grafana/alloy` itself is ahead at `v1.11.3`,
but the **chart** hasn't republished past `1.11.1` yet; tracked the chart, not the app
repo, consistent with how this lab pins every Helm-delivered component), **mimir**
`3.1.4` (newest `mimir-3.1.x`), **tempo** `2.10.7` (newest `v2.10.x`), **rabbitmq**
`4.3.4` (newest `v4.3.x`), **valkey** `8.0.10` (newest `8.0.x`), **k3s** `v1.36.3+k3s1`
(newest `v1.36.x+k3sN` — the `-` vs `+` separator difference between the git tag and
the Docker image tag is k3s's own convention, not a lab discrepancy), **gitlab-ce**
`19.2.1-ce.0` (newest `v19.2.x-ee` tag on GitLab.com's mirrored tag scheme — GitLab
doesn't publish separate CE tags, CE and EE share the same version number), **gitlab-
runner** `v19.2.1` (newest), **kyverno chart** `3.8.2` (newest, confirmed via the
`kyverno/kyverno` `gh-pages` branch's packaged `.tgz` list — the `kyverno-chart-vX.Y.Z`
git-tag scheme was retired after `2.5.5`), **trivy** (CLI/scanner) `v0.73.0` (newest —
same version this lab's Trivy Operator already bundles per its 2026-08-07 bump),
**argocd** (Terraform-bootstrapped chart `10.3.0`/binary `v3.5.0`) both newest per this
fetch pass.

---

## Ecosystem

- **Kubernetes**: not independently re-checked this pass — no new lab-pin action
  implied regardless (k3s's own release cadence is the lab's actual dependency
  surface, already checked above).
- **Longhorn app repo** (`longhorn/longhorn`): the `-dev-*`/`-rc*` prerelease tags
  ahead of `v1.11.3` (up through `v1.11.4-dev-20260726`) confirm active development on
  the next patch, but nothing stable has shipped past `v1.11.3` yet — no action.

---

## For the architect

- **New RFC opened this cycle**: `RFC: Grafana Unified Alerting for known failure
  conditions` — closes ROADMAP's new 🟡 item (added last cycle, `plan/alerting-rfc-gap`)
  and `docs/dora-audit-readiness.md` Q7. Decision: use Grafana's own built-in Unified
  Alerting (already part of the adopted chart, ADR-0006) evaluating against Mimir as
  its existing datasource — not Mimir's own ruler component (wired via
  `ruler_storage`/`rule_path` in `gitops/observability/mimir/configmap.yaml`, but
  never actually loaded with rules; this stays dormant, noted as a flip condition if a
  future need for recording rules — as opposed to alerting rules — arises). Rules
  provisioned via Grafana's file-based alerting provisioning (same declarative,
  GitOps-friendly shape as the chart's existing datasource/dashboard provisioning —
  no new component, no new ADR). Visual-only: no external notification receiver (no
  pager/Slack/email channel exists anywhere in this lab; ADR-0025's free/OSS-tier
  constraint and the absence of any existing channel to wire a receiver to make this
  the obvious default, stated explicitly as a non-goal rather than left as a silent
  gap). Starting rule set (four rules, each on a metric already confirmed scraped and
  in active dashboard use — no invented metric names): ArgoCD app unhealthy for 10m+,
  ArgoCD app out-of-sync for 30m+, a Deployment's available replicas below spec for
  10m+, a PersistentVolumeClaim stuck `Pending`/`Lost` for 10m+. See the RFC issue for
  the exact PromQL per rule.
- No ADR audits opened or closed this cycle — no open `adr-audit` issues found, and no
  upstream finding this pass met STEP 2b's "meaningfully changes the tradeoff" bar for
  any existing ADR'd component.

---

## Cadence

This is the second entry produced under `architect.prompt.md` STEP 1c's now-mandatory
digest-write contract (the first resumption entry was
[2026-W32](2026-W32-digest.md), written 2026-08-06/07). The mechanism continues to
hold: this file exists because this run's fourth cycle reached the ARCHITECT fallback
role, and that role's own contract requires writing/refreshing this file
unconditionally, not because anyone remembered to do it by hand.

---

## 2026-08-11 refresh (same ISO week, fourth cycle of a later run)

Reached the ARCHITECT fallback role again — Now/next's three standing items were
re-checked and found still gated (unchanged) on #631/#633 (both last updated
2026-08-07); no un-RFC'd 🟡 item and no unpromoted 🟢 item anywhere else in
ROADMAP.md (the planner-fallback cycle immediately before this one confirmed the
same); no open `adr-audit` issues. Per STEP 1c, refreshing this same-week file in
place rather than writing a second one.

Given the exhaustive 20+-component sweep above is under 24 hours old, this pass
spot-checked only the two highest release-velocity pins rather than re-fetching
everything:

- **k3s** (`k3s-io/k3s`) — `v1.36.3+k3s1` (published 2026-08-04 19:42 UTC) remains
  the newest tag on the `1.36.x` line this lab tracks; a parallel `v1.35.7+k3s1`
  release exists on the older `1.35.x` line (also 2026-08-04) but is not newer —
  confirmed directly against the real releases page, not assumed from a search
  summary (an initial web-search summary mis-read the page and claimed `v1.35.7`
  was "the latest release" outright; re-fetching the actual page corrected this
  before it went anywhere near a ROADMAP claim, per ADR-0004). No action.
- **ArgoCD** (`argoproj/argo-cd`) — `v3.5.0` (published 2026-08-04) remains newest;
  matches this lab's already-pinned binary version exactly. No action.

No new RFCs opened, no ADR audits opened or closed this pass — nothing found that
meets STEP 2b's "meaningfully changes the tradeoff" bar.
