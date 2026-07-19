# DORA resilience mapping — an educational lens, not a compliance claim

> **This document does not assert DORA regulatory compliance.** The EU Digital
> Operational Resilience Act (Regulation (EU) 2022/2554) binds a closed,
> enumerated list of "financial entities" (Article 2: credit institutions,
> payment institutions, investment firms, insurance/reinsurance undertakings,
> crypto-asset service providers, crowdfunding platforms, credit rating
> agencies, and roughly a dozen other categories) and their designated
> "critical" ICT third-party providers. **k8s-lab is a personal Kubernetes
> learning project. It is neither a financial entity nor a designated critical
> ICT third-party provider, has no relationship with any EU competent
> authority, and undergoes no DORA supervisory process.** Nothing below is a
> claim that this repo satisfies any DORA legal obligation. It is a mapping
> exercise: DORA's five pillars are a well-structured lens for describing
> general cloud-native operational-resilience *practice*, and this lab
> genuinely exercises several of them — this document names which, and cites
> exactly what already exists in the repo as evidence (RFC #586).

## Pillar 1 — ICT risk management framework

DORA Chapter II (Articles 5–16) requires a documented, governed ICT
risk-management framework. This repo's closest real analog is its
[Architecture Decision Record](decisions/) process: every meaningful technical
choice is written down, binding, and revisited on a schedule (the architect
routine's weekly ADR-audit sweep). CLAUDE.md's mandatory bugfix-recurrence-guard
rule — every bugfix must ship a mechanical guard, not just a symptom fix — is a
concrete instance of *treating risk as something to structurally close off*,
not merely document. Evidence:

- [ADR-0016](decisions/adr-0016-default-deny-networkpolicy.md) — default-deny
  NetworkPolicy per namespace, Cilium-enforced.
- [ADR-0017](decisions/adr-0017-pod-security-standards-restricted.md) — Pod
  Security Standards `restricted` profile across namespaces.
- [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) — continuous
  vulnerability + SBOM scanning.

## Pillar 2 — ICT-related incident management, classification, reporting

DORA Articles 17–23 require incident detection, classification, and reporting.
This lab has no live traffic and no formal incident process, but it does have a
real, git/CI-history-derived signal: `main`'s CI health. `make dora-metrics`
(RFC #580, CHARTER Objective O7) computes a genuine "time to restore service"
metric — the wall-clock delta between a CI run going red and the next run going
green, queried from the actual GitHub Actions API, never fabricated. See the
"Time to restore service" row in [`docs/dora-metrics.md`](dora-metrics.md) —
regenerate it with `make dora-metrics`; a value of "insufficient data" there
means exactly that (no `gh`/`jq`, or no CI failures in the window), never an
invented number.

## Pillar 3 — Digital operational resilience testing

DORA Articles 24–27 require regular resilience testing. This is the strongest,
most literal mapping of the five: `make dr-verify`, `make dr-test`, and
`make dr-bluegreen` are real, runnable recovery drills, not aspirational
descriptions — `make dr-test` destroys and rebuilds the lab from scratch and
verifies it; `make dr-bluegreen` stands up a second cluster and cuts over with
zero downtime. See [docs/DR.md](DR.md) for the full drill catalogue.

## Pillar 4 — ICT third-party risk management

DORA Articles 28–44 require managing risk from third-party ICT providers. This
lab's closest analogs are supply-chain controls over the third-party software
(Helm charts, container images) it depends on:

- [ADR-0022](decisions/adr-0022-trivy-operator-supply-chain.md) — Trivy
  Operator's continuous vulnerability + SBOM scanning of every deployed image.
- `scripts/helm-chart-pin-check.sh` — a drift detector asserting every
  Helm-chart `Application` pins a `targetRevision` that actually exists in its
  chart repo (no unpinned, no silently-moving version).
- [ADR-0025](decisions/adr-0025-free-oss-tiers-only.md) — every dependency this
  lab adopts must run entirely on a free/open-source tier, a deliberate
  constraint on the third-party surface this lab is willing to expose itself
  to.

## Pillar 5 — Information-sharing arrangements

**Not applicable.** DORA Article 45 concerns cyber-threat-intelligence sharing
arrangements between financial entities. Nothing in a solo personal learning
lab maps to this pillar honestly — there is no peer institution to share
threat intelligence with. Stated explicitly here rather than omitted, so the
absence reads as considered, not overlooked.
