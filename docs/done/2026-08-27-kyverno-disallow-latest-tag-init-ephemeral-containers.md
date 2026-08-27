# Extend `disallow-latest-tag` Kyverno policy to cover `initContainers`/`ephemeralContainers`, not just `containers`

Bugfix, not a ROADMAP item: reached via `executor.prompt.md` STEP 6b / ROADMAP
rule #9 after cycles 1–2 of this run exhausted the fallback chain (cycle 1
fixed real doc drift, PR #1350; cycle 2's `[Action needed]` PR #1351 found
nothing further after a genuinely different sweep). Cycle 3 tried yet another
fresh lens: an adversarial read of every Kyverno `ClusterPolicy` in
`gitops/kyverno/policies/`, checking each `validate`/`mutate` block against
every Pod sub-field it could plausibly need to cover, not just the ones it
already covers.

## Finding

`gitops/kyverno/policies/disallow-latest-tag.yaml`'s `validate.foreach` only
iterated `request.object.spec.containers` — `spec.initContainers` and
`spec.ephemeralContainers` were never checked. Unlike
`require-pod-security-restricted` (whose own `spec.containers`-only pattern
check is backstopped by the cluster's native Pod Security Admission, which
does enforce PSS-restricted on every container kind, init and ephemeral
included), `disallow-latest-tag` is a *Kyverno-only* rule — Kubernetes has no
built-in "no `:latest` tag" admission control. A chart-injected initContainer
(a common Helm pattern for wait-for-dependency or database-migration steps)
using `:latest` or no tag at all would have been silently admitted, with no
other control in the stack catching it. This was a real, unbackstopped
enforcement gap, not a defence-in-depth nicety.

Verified directly (ADR-0004): grepped every file under `gitops/` for
`initContainers:`/`ephemeralContainers:` — zero manifests define either field
today. This closes the gap structurally ahead of ever being hit, not in
response to an observed violation.

## Fix

Added two more `foreach` entries to `disallow-latest-tag.yaml`'s single
`validate` rule — `request.object.spec.initContainers` and
`request.object.spec.ephemeralContainers` — with deny conditions identical to
the existing `spec.containers` entry (`:latest` suffix, or no `:` at all).
Kyverno resolves a `foreach.list` that JMESPaths to a null/absent field as
zero iterations rather than an error, so this is safe for every pod shape,
including the overwhelming majority that set neither field — confirmed this
behavior against the official Kyverno policy library's own convention of
checking all three container kinds as separate `foreach` entries for exactly
this reason.

Added regression coverage in `tests/kyverno.bats`:
- a count/shape assertion (`foreach | length` is 3, each entry's `list` names
  the right field);
- a content assertion (the `initContainers`/`ephemeralContainers` entries'
  `deny.conditions` are byte-identical JSON to the `containers` entry's), so a
  future edit can't silently let the new entries drift out of sync with the
  original or narrow the policy back down to `containers`-only without a test
  failing.

Added a Re-evaluation log entry to `docs/decisions/adr-0019-kyverno-admission-engine.md`
(mirroring its existing carve-out-history entries' style) and updated
`docs/dependency-register.md`'s Kyverno row's "Last reviewed" date/summary to
match (caught by the repo's own `dependency-register-sync-hook.sh` PostToolUse
hook when it fired on the ADR edit).

## ADR-0004 caveat

This is a policy-config change validated structurally (the YAML parses, the
`foreach` shape is correct per Kyverno's documented semantics, `make ci` is
green) — this remote clusterless session has no live cluster to admit a test
Pod with an initContainer against and observe the rejection directly. The
change is additive and matches an established, documented Kyverno pattern
(checking all three container-kind fields), not a novel untested mechanism.

## Verification

Downloaded the real `mikefarah/yq` binary (the variant this repo's CI/hooks
require, `-o=json` output) to validate the new bats assertions properly
rather than trusting python-yq's incompatible flag handling locally. Full
`make ci` with `mikefarah/yq` on `PATH` — 2913/2913 bats assertions pass, zero
`not ok`, all drift checks (including the ADR/dependency-register sync checks
this PR's own edits triggered) green, exit 0.

## PR

auto/kyverno-disallow-latest-tag-init-ephemeral-containers
