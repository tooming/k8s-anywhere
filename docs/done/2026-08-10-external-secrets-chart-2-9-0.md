# Bump External Secrets Operator chart `2.8.0` → `2.9.0` (real CVE fixes)

(CHARTER **Core Values** §"Everything as code" + general hardening; executor-fallback
currency sweep 2026-08-10, reached via `executor.prompt.md` STEP 6b — the only three
unchecked items anywhere in ROADMAP.md (the standing Now/next trio) remain gated on
unconfirmed maintainer-confirmation issues #631/#633/#1034 (re-checked this cycle:
all three issues' full comment threads read directly, latest comments 2026-08-07,
still reporting live-cluster host-capacity/Harbor-stability blockers, no confirmation).
PLANNER-fallback intake pass found nothing to groom — `gh issue list` equivalent (GitHub
MCP tools, no `gh` CLI in this remote session) shows exactly the same three standing
`[Action required]` issues, already correctly labeled; `docs/roadmap/incoming/` holds
only its README; no un-RFC'd 🟡 item exists anywhere in ROADMAP.md (all prior 🟡 entries
are struck through/resolved, confirmed by grepping the file). This cycle's fresh angle
(3 days after the prior sweep on 2026-08-07, which had already checked ArgoCD, Trivy
Operator, Grafana, Tempo, Loki, kube-state-metrics, Harbor, Kiali, kro, envoy-gateway,
pyroscope, node-exporter, velero, ack-s3, cilium): a fresh `git ls-remote --tags` sweep
of chart repos not re-checked in that pass — cilium (current), argo-rollouts (current),
harbor (current), istio (current), kro (current), longhorn (a `v1.11.4` tag exists but
is a `-dev-*` prerelease only, no real release past `1.11.3`, false-positive ruled out
by checking the raw tag) — surfaced External Secrets Operator one minor version behind.
**No prerequisites — executor may pick up immediately.**) Verified directly (not
assumed, ADR-0004): `git ls-remote --tags external-secrets/external-secrets` shows
`helm-chart-2.9.0` as the newest tag on the chart's own tagging scheme, one release
past the pinned `2.8.0` (both `version` and `appVersion` move together in `Chart.yaml`,
confirming this is a real upstream app release, not a same-appVersion repackage). A full
clone diff (`git diff helm-chart-2.8.0 helm-chart-2.9.0 -- deploy/charts/external-secrets/`)
is purely additive: two new optional pod-scheduling fields (`schedulerName`,
`runtimeClassName`, each `{{- if .Values.X }}`-gated, default empty — no behavior change
unless explicitly set) across all three Deployments; a new `certController.enablePartialCache`
toggle (defaults `true`, scopes the cert-controller's informer cache to CRDs/
ValidatingWebhookConfigurations carrying the `external-secrets.io/component` label — a
narrowing, not a widening, of watch scope); the CRD bundle diff is schema-field
reordering only, nothing removed. The upstream release notes name two real CVE fixes:
`grpc-go` bumped addressing GHSA-hrxh-6v49-42gf, and `golang.org/x/text` bumped to
`v0.40` addressing CVE-2026-56852 — the same "ships with a real security fix" bar this
repo's other non-major currency bumps use, not a blind patch assumption. Also plus
real bug fixes (Akeyless provider error-handling + a data-race fix, AWS Secrets Manager
replicated-region detach-before-delete, webhook event-format standardization, an
ExternalSecret strategy-field over-defaulting fix) — none of which touch this lab's own
`valuesObject` keys (`installCRDs`, `podSecurityContext`, `securityContext`, `webhook.*`,
`certController.*`, `resources`), all of which are present and unchanged in the new
schema.

Bump `gitops/platform/external-secrets.yaml`'s `targetRevision: 2.8.0` → `2.9.0`. New
`tests/external-secrets-chart-pin.bats` (clusterless structural, mirrors this repo's
other exact-version-pin test pairs, e.g. `tests/observability-loki.bats`): asserts the
Application pins `targetRevision: 2.9.0`; asserts it does NOT pin the stale `2.8.0`
(recurrence guard). No `docs/dependency-tree.md` or `docs/decisions/context.md` update
needed — neither cites this chart's specific version (checked directly). **Honest note
for a future planner/architect cycle:** External Secrets Operator has no row in
`docs/dependency-register.md` and no dedicated ADR of its own (unlike RabbitMQ/Valkey/
Kyverno/etc., each with a decision ADR) — the register's own construction rule
("every row cites the ADR that decided it") structurally excludes it, the same gap
shape GitLab/LGTMP had before RFC #1073 closed it with ADR-0033/ADR-0034. Not fixed in
this PR (out of scope — one item per cycle, and authoring a new ADR is architect-role
work per WAYS-OF-WORKING.md), but flagged here so it isn't lost. `make ci` must pass.
PR body must document the CVE findings above and the ADR-0004 caveat that this remote
clusterless session cannot verify the ESO controller/webhook/cert-controller start
cleanly and continue syncing secrets post-bump on a live cluster — call out the
rollback path (revert `targetRevision`; ArgoCD re-syncs the prior chart version on its
next reconciliation; ESO holds no persistent state of its own — secrets it manages
live as native k8s Secrets, untouched by a chart-version revert). `docs/done/` entry
required. (auto/external-secrets-chart-2-9-0)

## PR

https://github.com/tooming/k8s-anywhere/pull/1081
