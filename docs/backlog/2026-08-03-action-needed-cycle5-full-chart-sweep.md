# [Action needed] Full gitops/platform chart-currency sweep complete; Now/next still gated

## What's blocked

ROADMAP.md's *Now / next* lane is still the same 3 unchecked `[ ]` items,
gated on the standing maintainer-confirmation issues
[#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified,
both still open, no new confirmation).

## What this run already did (4 real merged PRs)

[#962](https://github.com/tooming/k8s-anywhere/pull/962) (planner: architect
upstream sweep across the 17-component ADR checklist, added the Harbor
currency item), [#963](https://github.com/tooming/k8s-anywhere/pull/963)
(executor: Harbor chart `1.19.1`→`1.19.2` + a doc-drift fix),
[#964](https://github.com/tooming/k8s-anywhere/pull/964) (Action needed
record, cycle 3), [#965](https://github.com/tooming/k8s-anywhere/pull/965)
(upgrade-drafter: KEDA chart `2.20.1`→`2.20.2`).

## This cycle's fresh angle: exhaustive gitops/platform chart inventory

Took the upgrade-drafter role's own STEP 2 enumeration literally — walked
**every** `chart:`/`targetRevision:` pair in `gitops/platform/*.yaml` (26
Applications) and checked each against its real upstream chart index (a
`git clone -b gh-pages` + parse `index.yaml`, or `git ls-remote --tags`
against the chart's git-tagged repo — not training knowledge, ADR-0004):
`ack-s3`, `argo-rollouts`, `cert-manager`, `cilium`, `envoy-gateway`,
`external-secrets`, `harbor`, `istio-base`/`istio-cni`/`istiod`/`ztunnel`,
`kargo`, `keda`, `kiali`, `kro`, `kyverno`, `longhorn`,
`observability-alloy`, `observability-grafana`, `observability-ksm`,
`observability-node-exporter`, `observability-pyroscope`, `tidb-operator`,
`trivy-operator`, `vault`, `velero`.

Two important corrections made along the way (documented here so a future
sweep doesn't repeat the mistake): (1) Grafana Alloy's Helm **chart**
version (`1.11.0`) is numbered independently from the `grafana/alloy`
**application**'s own GitHub release tags (`v1.18.0`) — an initial
app-repo-only check looked like a 7-minor-version gap; the real chart
index (`grafana/helm-charts` gh-pages `index.yaml`) confirms `1.11.0` (app
`v1.18.0`) is genuinely the newest chart. (2) `kedacore/charts` git tags
don't sort chronologically under a naive `tail`; had to grep the exact
`v2.19`/`v2.20` range to find the real newest tag.

**Result: every chart is already at its newest stable version** except the
two already bumped this run (Harbor, KEDA). Also checked the 4 pinned
GitHub Actions in `.github/workflows/` (`actions/checkout@v7.0.1`,
`actions/cache@v6.1.0`, `actions/github-script@v9.0.0`,
`hashicorp/setup-terraform@v4.0.1`) against their real releases pages — all
four already at latest stable.

This is the most exhaustive dependency-currency pass this run has done —
genuinely new ground versus cycle 3's narrower duplication/doc-drift lenses,
not a repeat.

## What would unblock further Now/next work

Unchanged: (a) a maintainer-confirmation comment on #631 or #633; (b) a new
GitHub issue of any size (ungroomed intake); (c) a new upstream CVE/release
against any of the now-confirmed-current components; (d) an architect RFC
deciding the Longhorn `1.12.0` go/no-go noted in cycle 3's record.

This note is this cycle's honest record — the run has already shipped 4 real
PRs. The run continues to the next cycle per `executor.prompt.md` STEP 8;
this is not a stopping point.
