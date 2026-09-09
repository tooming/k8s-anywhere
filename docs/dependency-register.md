# Third-party dependency register

A single, queryable register of this lab's third-party dependencies — closing
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md)'s Q14 ("Is there a register
of ICT third-party dependencies?"), which named this exact gap as "real but cheap to
close... without gathering new information." Every row below is pure re-indexing of
content that already exists in [`docs/decisions/`](decisions/) (the ADRs) — no new
dependency-risk judgment was made in producing this file.

**How this relates to the other two dependency docs** (they answer different
questions, not duplicates of each other):
- [`docs/decisions/`](decisions/) — the **why**: the full reasoning, rejected
  alternatives, and re-evaluation history behind each choice.
- [`docs/dependency-tree.md`](dependency-tree.md) — the **topology**: how components
  wire together in GitOps (namespaces, sync waves, NetworkPolicy paths).
- **This file** — the **third-party-risk rollup**: at a glance, which upstream
  projects the lab depends on, how critical each is, and when it was last reviewed.

## Scope note

Of the 42 ADRs indexed in [`docs/decisions/README.md`](decisions/README.md)
(ADR-0001–ADR-0042), two are **Superseded** and fully excluded per the index's own
convention (only a live replacement is listed, when one exists): ADR-0010 (Redis,
superseded by ADR-0018/Valkey — Valkey itself was later removed entirely, see
below) and ADR-0008 (Envoy Gateway, superseded by ADR-0040/Traefik) each have (or
had) a live replacement counted in their place. ADR-0011 (Artifactory, superseded
by ADR-0024/Harbor) and ADR-0033 (GitLab, superseded by ADR-0035/Forgejo) once
followed the same pattern, but both eventual replacements — Harbor and Forgejo —
were themselves removed entirely with no replacement 2026-09-07 (see below), so
neither the original nor the superseding ADR contributes a row any more. ADR-0006
(Grafana's native Git Sync) and ADR-0034 (the LGTM(P) stack internals — Mimir,
Loki, Tempo, Pyroscope, Alloy, plus kube-state-metrics/node-exporter) were both
superseded 2026-09-06 by
[ADR-0041](decisions/adr-0041-remove-observability-stack.md), which removes every
tool either one named **with no replacement at all** — so unlike ADR-0010/ADR-0008,
their eight combined tool-rows (Grafana, Mimir, Loki, Tempo, Pyroscope, Alloy,
kube-state-metrics, node-exporter) are simply gone, not reassigned. The remaining
two, ADR-0036 (External Secrets Operator) and ADR-0037 (Vault), were both
superseded 2026-09-07 by
[ADR-0042](decisions/adr-0042-remove-vault-and-external-secrets.md) the same
way — explicit maintainer direction, no replacement — so their two combined
tool-rows (External Secrets Operator, Vault) are simply gone too; ESO had zero
live `ExternalSecret` consumers left in the repo by the time it was cut (every
component that had ever needed a Vault-held credential was already gone).

Of the remaining 34, **ten decide a policy or architectural posture rather than a
single third-party product** — they're excluded from the table below because there's
no one upstream project to attach a criticality/upstream-source/last-reviewed row to:
ADR-0003 (decoupled/no-SPOF design principle), ADR-0004 (no-fabricated-content
policy), ADR-0005 (recreate-over-HA posture), ADR-0016 (default-deny NetworkPolicy
pattern — enforced via k3s's bundled Flannel + kube-router since Cilium was removed
2026-09-07, see below), ADR-0017 (Pod Security Standards — a built-in Kubernetes
admission feature, not a third-party dependency), ADR-0025 (free/OSS-tier
governance rule), ADR-0026 (cloud-agnostic architecture policy), ADR-0030 (k3s
version-pinning governance — no separate row of its own, but directly cited
alongside ADR-0027 in the k3s row's ADR column since 2026-08-24, once a
gap-analysis pass found the row's "Last reviewed" cell citing only ADR-0027's
decision date and missing ADR-0030's own, much more current, Re-evaluation log
entirely), ADR-0041 (the observability-removal decision itself — a
scope-narrowing choice, not a third-party product of its own), and ADR-0042 (the
Vault/External Secrets Operator removal decision itself — same shape as ADR-0041).

Of the remaining 24, twenty-one name a component that was removed from the lab
entirely with no replacement, so they contribute no row either: ADR-0012 (Istio
ambient + Kiali), ADR-0013 (Longhorn), ADR-0015 (Aiven Inkless — a pre-existing
gap, never had a row of its own), ADR-0031 (TiDB Operator), ADR-0032 (TiDB),
ADR-0009 (RabbitMQ), ADR-0018 (Valkey), and ADR-0029 (KEDA) — all removed
2026-09-06 — plus ADR-0002/ADR-0007 (Garage, both in-cluster S3 and the
off-cluster Terraform-state backend), ADR-0011/ADR-0024 (Artifactory → Harbor),
ADR-0014 (Cilium), ADR-0019 (Kyverno), ADR-0020 (Argo Rollouts), ADR-0021
(Velero), ADR-0022 (Trivy Operator), ADR-0023 (Kargo), ADR-0033/ADR-0035 (GitLab
→ Forgejo), ADR-0038 (moto + ACK S3 + KRO, three tool-rows at once), and
ADR-0039 (s3manager, Garage's browser UI, orphaned the same day Garage itself
went) — all removed 2026-09-07 — see each ADR's own Status. (Cilium's own row is
the one exception to "removed = no row": its Re-evaluation log is recent and
informative enough — the live host-capacity evidence that drove the removal — to
be worth keeping as a dated historical entry rather than deleting outright; it's
the only "removed" row still in the table.) The other 3 all have a row below —
collectively naming the table's 7 distinct third-party-tool rows: two ADRs each
decide on more than one tool at once (ADR-0001: Terraform/Terragrunt + ArgoCD;
ADR-0027: Oracle Cloud Infrastructure + k3s).

**Criticality** reuses CHARTER's own "Target end-state" groupings rather than
inventing a new scheme: **always-on-core** (part of the always-on base stack),
**always-on-next-wave** (the four CHARTER Objective O1 components), **heavy-on-demand**
(manual `make <name>-up`/`-down`, never auto-synced), or **cloud-backend (opt-in)**
(ADR-0027's alternate Oracle Cloud infra path — not part of the localhost budget
tiers at all, since it's an operator-chosen alternative to the default backend, not
a component running alongside it).

**Last reviewed** is the most recent dated entry in the ADR's own "Re-evaluation log"
section where one exists; where an ADR has no such section *and* states no explicit
decision date in its `Status` line either, this is marked **"not dated in ADR"**
rather than guessed (ADR-0004 — never fabricate a date not actually in the source).

| Tool | Criticality | Upstream source | ADR | Last reviewed |
|---|---|---|---|---|
| Terraform / Terragrunt | always-on-core (day-0 bootstrap only, ADR-0001) | terraform.io, github.com/hashicorp/terraform, terragrunt.gruntwork.io | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | 2026-09-06 (JANITOR-fallback currency sweep — first review this row had ever recorded; ADR-0001 has no dedicated Re-evaluation log of its own, same shape as this run's ArgoCD sweep, so the result is recorded here directly. Terraform bumped `1.15.9`→`1.16.1`: routine currency, hashicorp/terraform's only published GitHub security advisory — GHSA-4rvg-555h-r626, an Azure-backend cleartext-state issue from 2019 — doesn't apply, this repo has never used an Azure backend (its local-lab tfstate backend is now a plain local file, ADR-0007 superseded 2026-09-07 when Garage — its only S3 backend candidate — was removed with no replacement). Terragrunt bumped `v1.1.3`→`v1.1.4`: real security hardening, tightened generated-file permissions (0600/0700) + reduced credential duplication, no CVE filed. Both checked against their real release notes directly for breaking changes — none apply to this repo's actual usage. Full writeup: [docs/done/2026-09-06-terraform-terragrunt-currency-bump.md](done/2026-09-06-terraform-terragrunt-currency-bump.md)) |
| ArgoCD | always-on-core | argoproj.github.io, github.com/argoproj/argo-cd | [ADR-0001](decisions/adr-0001-gitops-over-terraform-helm.md) | 2026-09-08 (chart `10.5.0`→`10.8.2`, appVersion unchanged at `v3.5.2` — a pure Helm-chart-packaging bump (dependency/values maintenance only), verified directly against both tags' `Chart.yaml`; `global.networkPolicy.create` still defaults to `true` upstream at `10.8.2` (checked directly against the chart's `values.yaml`), so this repo's `global.networkPolicy.create: false` override (RFC #785) is still required and correct — no GHSA re-sweep needed since the app version didn't move past the 2026-09-03 full sweep below. Prior entry: 2026-09-03, full GHSA sweep: all 8 published `argoproj/argo-cd` advisories checked — highest severity Critical (GHSA-3v3m-wc6v-x4x3/CVE-2026-42880, ServerSideDiff secret extraction, fixed `3.2.11`/`3.3.9`) — every affected range tops out at `3.4.2` or lower; current pin's appVersion `v3.5.2` is past every floor. Prior entry: 2026-09-01, chart `10.4.0`→`10.5.0`, appVersion `v3.5.1`→`v3.5.2`, routine currency) |
| Traefik (supersedes Envoy Gateway, ADR-0008) | always-on-core (bundled with k3s, no separate chart/version to track — see [ADR-0030](decisions/adr-0030-pin-k3s-version-explicitly.md)) | github.com/traefik/traefik (bundled by github.com/k3s-io/k3s) | [ADR-0040](decisions/adr-0040-traefik-not-envoy-gateway.md) | 2026-09-06 (full GHSA sweep of the k3s-bundled `v3.7.8` — 9 published advisories checked, all affect `v3.7.8` including one Critical (digestAuth complete auth bypass, GHSA-5w68-77r2-r64c); none of the 9 vulnerable code paths (digestAuth/basicAuth middlewares, Gateway API objects, `TLSOption`/mTLS, HTTP/3, `providers.kubernetesIngressNGINX` compat, cross-provider-namespace restrictions) are used anywhere in this lab's `gitops/` — confirmed by direct grep, not assumed. No newer k3s release yet bundles a fixed Traefik (`v3.7.11`/`v3.7.12`); flip condition: re-check when k3s ships one. Full writeup: [docs/done/2026-09-06-traefik-full-ghsa-sweep.md](done/2026-09-06-traefik-full-ghsa-sweep.md). Prior entry: 2026-09-06 decision date, not yet live-cluster-verified, see ADR-0040's own "Known risk" section) |
| Cilium | removed 2026-09-07, no replacement (ADR-0014) — k3s's bundled Flannel + kube-router is the CNI now | github.com/cilium/cilium | [ADR-0014](decisions/adr-0014-cilium-not-flannel-policy.md) | 2026-09-07 (removed entirely — host capacity found live with hard evidence, docs/incident-log.md, combined with the maintainer's "no replacement, aggressive simplification" direction this session; see ADR-0014's own Re-evaluation log. Prior entry: 2026-09-03, Critical GHSA-3fcv-jvfp-m4q9 confirmed not applicable, pin `1.18.13` past fix floor) |
| Oracle Cloud Infrastructure | cloud-backend (opt-in) | cloud.oracle.com | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | 2026-09-07 (currency re-check — first review this row had ever recorded; ADR-0027 has no dedicated Re-evaluation log of its own, same shape as the Terraform/ArgoCD/ADR-0001 rows above, so the result is recorded here directly. Re-confirmed the Always Free Ampere A1 cut this ADR already documents — 4 OCPU/24 GB → **2 OCPU/12 GB**, effective 2026-06-15 — is still accurate and unchanged; no further reduction has landed since. New fact found, not yet in the ADR: Oracle has since emailed Always Free users that any Ampere A1 instance still exceeding the new 2 OCPU/12 GB limit on or after **2026-08-18** gets terminated — a real deadline, but moot for this repo today since no live Oracle k3s instance has ever actually launched yet (blocked on the `500 Out of host capacity` transient constraint CHARTER.md's "Cloud backend" bullet already records) — nothing here to be terminated. The ADR's core "free forever, no trial/credit mechanism" comparison against AKS/GKE Autopilot still holds; no competing free-tier option has changed status. No code/config change; no currency gap requiring action.) |
| k3s | cloud-backend (opt-in) | github.com/k3s-io/k3s | [ADR-0027](decisions/adr-0027-first-cloud-backend-oracle-always-free-k3s.md) (backend choice) / [ADR-0030](decisions/adr-0030-pin-k3s-version-explicitly.md) (version pin + re-evaluation) | 2026-09-09 (currency re-confirmed via a live `github.com/k3s-io/k3s/releases` check: `v1.36.4+k3s1` — this repo's current pin on both the k3d and Oracle backends — is still the newest stable tag; the only entries beyond it are `v1.37.0-rc*` pre-releases, not a stable cut, so no bump is due. No code/config change. Prior entry: 2026-09-03, bumped `v1.36.3+k3s1` → `v1.36.4+k3s1` on both backends, routine currency — a release-list summary claimed a CVE-2025-54410 mitigation but the release's own detailed notes don't confirm it and the CVE describes Docker Engine behavior k3s doesn't run, so treated as unconfirmed rather than asserted; see ADR-0030's own Re-evaluation log, which tracks k3s's real version-currency history across both backends; ADR-0027 itself has no Re-evaluation log, decision date 2026-07-13) |
| cert-manager | always-on-core | github.com/cert-manager/cert-manager | [ADR-0028](decisions/adr-0028-cert-manager-tls-lifecycle.md) | 2026-09-09 (currency re-confirmed via a live `github.com/cert-manager/cert-manager/releases` check: `v1.21.1` — this repo's current pin — is still the newest stable tag (released 2026-07-29), so no bump is due; no new GHSA published against it since the 2026-09-03 full sweep below. No code/config change. Prior entry: 2026-09-03, full GHSA sweep: all 3 published advisories checked — the third, GHSA-r4pg-vg54-wxx4 Low (PEM-parsing DoS, patched `1.16.2`/`1.15.4`/`1.12.14`), had not been explicitly checked before — current pin `1.21.1` past every floor. Prior entry: 2026-08-19, GHSA-8rvj-mm4h-c258/GHSA-gx3x-vq4p-mhhv both past floor, no currency gap) |

## Keeping this in sync

**"Last reviewed" staleness is now mechanically guarded.** As of 2026-08-24,
`scripts/dependency-register-check.sh` (`make dependency-register-check`, wired into
`make ci`'s `drift` job) fails the build if any row's "Last reviewed" date is older
than the newest Re-evaluation-log entry of the ADR(s) cited in that row's ADR column —
the exact gap this section used to name ("nothing currently fails `make ci` if it
drifts"), closed after it bit real rows twice (Inkless/TiDB Operator/cert-manager,
2026-08-12; the k3s row, 2026-08-24 — see the script's own header comment for both).
Two honest limits remain, stated there rather than overclaimed: it can't check an ADR
that has no Re-evaluation log at all, and it can't invent a review date for an ADR
that never recorded one — both are gaps in the underlying ADR, not something this
guard could paper over.

**Register → concentration.md sync is now mechanically guarded too.** As of
2026-09-02/03, `scripts/dependency-concentration-sync-check.sh` (`make
dependency-concentration-sync-check`, also wired into `make ci`) counts how many rows
above share each `github.com` upstream org and fails if any org backing 2+ rows isn't
named in [`docs/dependency-concentration.md`](dependency-concentration.md) — the
"future row add/remove/rename here should prompt a look there too" caveat this section
used to state as a manual-only expectation is now enforced, not just hoped for. It
checks one direction only (a real concentration point missing from concentration.md);
it does not check the reverse (a concentration.md entry with no matching register
rows) — a real, separately-scoped gap, same partial-coverage shape as this repo's
other drift guards (e.g. `adr-chart-version-sync-check.sh` only checks ADRs that
self-declare a chart-version note).

[`docs/dependency-concentration.md`](dependency-concentration.md) is a downstream
consumer of the table above (grouped by upstream GitHub org, closing
[`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q16's gap) — see that file's
own "Keeping this in sync" section for how its sync to
[`docs/dependency-exit-runbooks.md`](dependency-exit-runbooks.md) (Q17) is guarded.
