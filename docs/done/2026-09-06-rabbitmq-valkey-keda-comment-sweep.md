# Fix 4 stale RabbitMQ/Valkey/KEDA references in `gitops/` header comments (post-2026-09-06-removal drift)

ADR-0004; JANITOR-fallback coverage sweep 2026-09-06, following up on the same-day
RabbitMQ/Valkey/KEDA removal (ADR-0009/ADR-0018/ADR-0029, `chore: remove RabbitMQ,
Valkey, and KEDA entirely, no replacement`). Same "check every `gitops/` file for
lingering references to a just-removed component" pattern that already caught one
real stale comment each for the TiDB removal
([docs/done/2026-09-06-velero-networkpolicy-tidb-comment-fix.md](2026-09-06-velero-networkpolicy-tidb-comment-fix.md))
and the observability-stack removal earlier this run.

## What was found

`grep -rniI "rabbitmq\|valkey\|keda"` across `gitops/`, then manually triaged every
hit for whether it was a present-tense claim about current live state (a bug) versus
legitimate history (a dated note, a past-tense incident description, or a
`docs/done`/ROADMAP record) — the same triage ADR-0004 already required for the
TiDB and observability sweeps.

Four genuine present-tense staleness bugs:

1. **`gitops/vault/networkpolicy/allow-vault-from-eso.yaml`** — its header comment
   listed "all ExternalSecrets in the cluster (garage, rabbitmq, valkey, harbor,
   kargo, …)" as the current consumer set. Verified live via
   `grep -rl "kind: ExternalSecret" gitops/`: the real current set is
   harbor/garage/ack/kargo/capstone-app/velero — no rabbitmq or valkey
   ExternalSecret has existed since the removal.
2. **`gitops/external-secrets/networkpolicy/allow-eso-webhook-from-apiserver.yaml`**
   — compared its CiliumNetworkPolicy shape to "the `ipBlock` pattern used by
   gitops/kyverno, gitops/cert-manager, and gitops/keda's equivalent files" in the
   present tense. `gitops/keda` no longer exists (confirmed via `ls gitops/`) —
   its own webhook-from-apiserver file was removed 2026-08-25 when KEDA went
   on-demand-only, well before KEDA's full removal 2026-09-06.
3. **`gitops/platform/harbor.yaml`** — its ADR-0018-exception comment said Valkey
   "is otherwise unaffected" by Harbor's bundled-cache deviation, which reads as
   "Valkey is still running fine elsewhere" now that Valkey doesn't exist at all.
4. **`gitops/network/policies/zz-dns-clusterip-bridge.yaml`** — used
   `valkey.data.svc → 10.43.x.x` as its illustrative example of the general
   ClusterIP-egress problem; that Service no longer exists. Swapped for
   `vault.vault.svc`, a Service that does.

## What was deliberately left alone

`gitops/kyverno/policies/require-pod-security-restricted.yaml`'s comment names
"mimir, loki, tempo, moto, rabbitmq, valkey, …" as pods that got rejected during a
past PSS-policy-recovery incident ("the moment it recovered it rejected every
plain-manifest pod ... on restart"). That's a past-tense description of what
happened during a specific historical incident, not a present-tense claim that
these pods exist today — same category as ROADMAP's own `[x]` history, which this
run's convention leaves untouched. No fix needed.

`gitops/platform/governance-appset.yaml` and `gitops/platform/velero-schedules.yaml`
already carry correctly-dated "REMOVED 2026-08-25/2026-09-06" annotations from the
removal PRs themselves — already accurate, no fix needed.

## Verification

- `make ci` passes green on current `main`.
- No test depended on any of the fixed prose (these are header/inline comments
  only — no `spec:` field, selector, or `NetworkPolicy` rule changed in any of the
  four files).
- Re-ran the same `grep -rniI` sweep after the fix: zero remaining present-tense
  hits outside ROADMAP.md history, `docs/done/`, and the two already-dated removal
  comments.

## Result

`make ci` passes green. No `spec:`/behavior change in any of the four touched
files — comment/documentation accuracy only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1467
