# Harbor signed-image-pipeline verification runbook — consolidates issues #631/#633's live-session findings

(CHARTER **Core Values** §"Docs & dashboards don't drift" / operational-resilience
discipline; JANITOR-fallback bounded cleanup 2026-08-12, reached via
`executor.prompt.md` STEP 6b — the Now/next lane was re-confirmed fully gated for the
seventh cycle running this run, unchanged since 2026-08-11 on standing issues #631/
#633, and this cycle's own PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER
attempts found nothing new beyond the preceding six cycles this run. No prerequisites
— executor may pick up immediately.)

## What was wrong

Issues [#631](https://github.com/tooming/k8s-anywhere/issues/631) and
[#633](https://github.com/tooming/k8s-anywhere/issues/633) have been open since
2026-07-20 and have collected roughly a dozen live-cluster session comments between
them. Read start to finish, they show a real pattern: **every** attempt found and
durably fixed a genuine, distinct bug (Cilium apiserver drift, an intra-namespace
NetworkPolicy gap, a missing Envoy egress allowlist entry, stale Vault-held Harbor
credentials, a GitLab Runner that had never been registered, node disk pressure, a
9-hour Vault seal, too-tight probe timeouts, a NetworkPolicy port mismatch, a
namespace stuck `Terminating` for 20 days, a Kargo admission-webhook validation gap,
an `nip.io` in-cluster DNS resolution bug, a non-existent Helm field silently
swallowing Harbor's S3 credentials, and a Kyverno probe-timeout crashloop) — but none
has yet completed one full pipeline run start to finish, because verification kept
getting preempted by host resource exhaustion. Nothing was wrong with any individual
fix. What was missing: no single place consolidated *which* of these are already
fixed (so a new session doesn't re-diagnose them from scratch by re-reading 14
comments) and *what specifically* still needs to happen (a live verification window
with the right sequencing, not another code fix).

## Fix

Added a "Harbor signed-image-pipeline verification (issues #631 / #633)" subsection
to `docs/DR.md`'s existing "Recovery cookbook (single-component)" section — the
established home for this kind of consolidated incident-response guidance (mirrors
the existing "k3s embedded datastore health" entry's shape). Two parts:

1. **Already fixed and durably in git** — a numbered list of all 14 root causes found
   across every prior session, each citing its real PR number (or "fixed live, no PR"
   for non-GitOps-managed state like Vault secrets) and date, cross-checked directly
   against the actual issue-comment history and `docs/incident-log.md` before writing
   (not reconstructed from memory).
2. **What's genuinely still needed** — a concrete, ordered checklist synthesizing the
   sequencing advice multiple sessions independently arrived at (check the node
   disk-pressure issue #1034 first; bring Harbor up *alone*, not alongside Kargo or
   another heavy component; let it stabilize before triggering a pipeline; verify the
   `.sig` lands; only then bring Kargo up for the promotion check).

## Recurrence prevention

This is a documentation-consolidation fix, not a code bug — there's no `make ci` gate
to add for "did the next live session read this runbook first." The mechanical
prevention here is structural: the runbook now lives in `docs/DR.md`, the same file
every other recovery cookbook entry lives in and that live-cluster sessions already
consult, rather than requiring a fresh re-read of two issues' full comment threads
every time.

## What's blocked (unrelated to this fix)

The same six Now/next items remain gated (three sequential Forgejo-migration items;
`verifyImages` Enforce-flip + O4 CI gate on unconfirmed issue #631; capstone
`Deployment` removal on unconfirmed issue #633) — re-checked directly, both still
open, no new comment since 2026-08-11. This runbook doesn't unblock them itself; it's
meant to make the *next* live-cluster session's attempt more likely to succeed.

## ADR-0004 caveat

Every fact in the runbook (root cause, PR number, date) was cross-checked directly
against the real issue #631/#633 comment history and `docs/incident-log.md` during
this session, not reconstructed from memory or invented. This remote clusterless
session cannot verify the runbook's "what's still needed" checklist actually works
against a live cluster — that's the whole point of the gap it's closing.

## Rollback path

Revert this commit — a single new subsection in `docs/DR.md` plus this record, no
other surface affected.

## PR

https://github.com/tooming/k8s-anywhere/pull/1168
