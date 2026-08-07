# `docs/dependency-register.md` — add rows for ADR-0033 (GitLab) and ADR-0034 (LGTMP observability internals)

(CHARTER **Core Values** §"Decisions written down"; architect-fallback follow-up
2026-08-07, RFC #1073 acceptance criteria's remaining unchecked box. **No
prerequisites — executor may pick up immediately.**) Added a `GitLab` row
(criticality `always-on-core`, source `about.gitlab.com`, `gitlab.com/gitlab-org/gitlab`,
citing [ADR-0033](../decisions/adr-0033-gitlab-git-source-and-ci.md)) and seven new
rows — one each for Mimir, Loki, Tempo, Pyroscope, Alloy, kube-state-metrics,
node-exporter (criticality `always-on-core`, each citing
[ADR-0034](../decisions/adr-0034-lgtmp-observability-stack.md)) — to
`docs/dependency-register.md`'s table, in the same row shape as every existing entry
(Tool / Criticality / Upstream source / ADR / Last reviewed, the last column dated
2026-08-07 with a one-line note "ADR-0033/ADR-0034 authored").

Edited the "Real gap, distinct from the policy-ADR exclusions above" paragraph to
record the gap as closed (both ADRs now exist, both new ADR files linked) rather than
leaving it describing a now-stale state. Updated the "Keeping this in sync" summary
line to note the eight new rows landed the same day as the ArgoCD/Trivy Operator
updates it already cited.

Doc-only change — no code, no `gitops/` touch. `make ci` green (readme-check +
internal-markdown-link-resolution cover this file; no drift-check currently enforces
this register's content per its own "no mechanical drift guard yet" note, unchanged
by this PR).

## PR

[#1076](https://github.com/tooming/k8s-anywhere/pull/1076)
