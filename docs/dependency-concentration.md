# Third-party dependency concentration risk

Closes [`docs/dora-audit-readiness.md`](dora-audit-readiness.md) Q16's own named gap:
concentration risk is assessed *per-decision* (every ADR names rejected alternatives,
itself an anti-concentration exercise), but that was never rolled up into a single
cross-cutting view of which single upstream repo, registry, or chart source, if it
disappeared, would break the most components at once. This file is that rollup — a
genuinely new artifact, not a re-index of
[`docs/dependency-register.md`](dependency-register.md) (whose own header scopes that
file as pure re-indexing, with no new dependency-risk judgment made in producing it).

## Method

Group every one of `docs/dependency-register.md`'s 26 GitHub-hosted tool rows
(of 29 total; the other 3 — Terraform/Terragrunt, Oracle Cloud Infrastructure,
Forgejo — aren't GitHub-hosted, so there's no GitHub org to group them by) by
**upstream GitHub org**, reusing the register's own "Upstream source" column
verbatim (nothing re-derived from memory), and flag any org backing more than
one row as a concentration point.

## Findings, worst-first

**`github.com/grafana` — removed 2026-09-06 (ADR-0041).** This used to be the
largest single concentration in the table (6 tools: Grafana, Mimir, Loki, Tempo,
Pyroscope, Alloy) — the entire observability pane maintained by one upstream org.
The observability stack was removed entirely with no replacement (ADR-0041,
supersedes ADR-0006/ADR-0034); none of those six rows exist in the register any
more, so this is no longer a concentration point to track.

**`github.com/argoproj` — 2 tools:** ArgoCD, Argo Rollouts. `always-on-core` and
`always-on-next-wave` respectively — now the largest single concentration in the
table (the `github.com/grafana` cluster that used to be larger no longer exists,
per the note above).

**Every other row is a distinct org** — Terraform (hashicorp) and Terragrunt
(gruntwork-io) are two different orgs sharing one register row; Garage (Deuxfleurs);
Traefik (traefik, bundled with k3s — no separate org row of its own to track since ADR-0040); RabbitMQ (rabbitmq); Cilium
(cilium); Valkey (valkey-io); Kyverno (kyverno); Velero
(vmware-tanzu); Trivy Operator (aquasecurity); Kargo (akuity); Harbor (goharbor);
Oracle Cloud Infrastructure (not GitHub-hosted — cloud.oracle.com); k3s (k3s-io);
cert-manager (cert-manager); KEDA (kedacore); Forgejo (not GitHub-hosted —
codeberg.org/forgejo, code.forgejo.org/forgejo); kube-state-metrics (kubernetes);
node-exporter (prometheus).
No further grouping applies — padding this section with 24 one-line "groups" of a
single tool each would not add information the register table doesn't already give
directly.

## Mitigation already in place

This lab doesn't need a new mitigation invented for this file — ADR-0001's own design
is already the answer: every workload is a GitOps `Application` pointing at a pinned
chart/image ref, so a disappeared upstream is a fork-the-source-and-repoint operation,
not a rebuild. This isn't theoretical: the ADR-0011→ADR-0024 Artifactory→Harbor
migration is a real, already-executed exit from one upstream provider to another (the
same precedent [Q17](dora-audit-readiness.md) already cites for exit strategy). The
`github.com/grafana` concentration this file used to name was resolved the same
way in the end — not by forking a replacement, but by removing the whole
observability stack outright with no replacement (ADR-0041) once the maintainer
narrowed the lab's scope; either path (fork-and-repoint or remove-outright) shows
this lab isn't structurally locked to any single upstream org.

## Keeping this in sync

This file is a downstream consumer of `docs/dependency-register.md`'s table. As of
2026-09-02/03, `scripts/dependency-concentration-sync-check.sh` (`make
dependency-concentration-sync-check`, wired into `make ci`'s `drift` job) mechanically
guards this direction: it fails the build if any register org backing 2+ rows isn't
named as a group here — a future register edit that grows an org past one row can no
longer silently skip this file. It checks one direction only (a register-side org
crossing the 2-row threshold); a concentration.md entry with no matching register rows
is a real, separately-scoped gap the check doesn't catch.

[`docs/dependency-exit-runbooks.md`](dependency-exit-runbooks.md) (Q17) is in turn a
downstream consumer of *this* file's three named concentration groups — that sync is
also now mechanically guarded: `scripts/dependency-exit-runbooks-sync-check.sh` (`make
dependency-exit-runbooks-sync-check`, wired into `make ci`'s `drift` job) fails the
build if a `github.com/ORG` group named above has no matching section in
`dependency-exit-runbooks.md`. It only checks concentration-GROUP coverage, not full
`always-on-core` single-tool-row coverage — see that file's own "Keeping this in sync"
section for its deliberate, documented partial scope.
