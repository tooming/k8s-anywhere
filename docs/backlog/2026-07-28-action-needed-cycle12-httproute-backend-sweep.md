# [Action needed] Now/next still gated; HTTPRoute backendRef sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped eleven real, merged deliverables (PRs
#789, #790, #792–#800), including two live-cluster bugfixes (#796, #797).

This cycle cross-checked every `HTTPRoute`'s `backendRefs` (name + port) against every
plain-YAML `Service` manifest found under `gitops/`. 8 of 15 HTTPRoutes' backends
appeared unresolved: `argo-rollouts-dashboard`, `longhorn-frontend`, `argocd-server`,
`vault`, `harbor`, `kiali`, `kargo-api`, `artifactory-oss`. All 8 are false positives
from the check's own blind spot (the same class already identified for the NetworkPolicy
coverage check in cycle 9): these Services are created by their component's Helm chart at
deploy time, not hand-authored as plain `Service` manifests in this repo, so a script
that only scans literal YAML `Service` resources can't see them.

Spot-checked the highest-risk candidate for real drift — **Kiali**, since its chart was
bumped `1.89.8` → `2.29.0` (a major version) earlier today, exactly the kind of change
that can rename a chart's generated Service. Verified directly against the live
`kiali-server` chart source (`templates/service.yaml` + `_helpers.tpl` +
`values.yaml`, fetched at `master`, matching the pinned `2.29.0`): the Service name comes
from `{{ .Values.deployment.instance_name }}` (chart default `"kiali"`, unmodified by
this repo's `gitops/platform/kiali.yaml` `valuesObject`) and the port from
`.Values.server.port` (chart default `20001`, likewise unmodified) — both match
`gitops/kiali/route.yaml`'s `backendRefs` (`name: kiali`, `port: 20001`) exactly. No
drift; the wiring is correct.

No actionable gap surfaced from this lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
