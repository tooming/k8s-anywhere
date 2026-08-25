# docs: log the Kargo capstone-pipeline namespace-deadlock incident (PR #1055)

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's tenth cycle. "Now / next" remains fully gated
(unchanged, issue #633) and the PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER fallback passes found nothing new this cycle
either. **No prerequisites — executor may pick up immediately.**

## The gap

Another real, undocumented incident from issue #633's comment history
(2026-08-07 session): the `capstone-pipeline` namespace had been stuck
`Terminating` for 20 days due to a chicken-and-egg deadlock, and — once
that cleared — a second, independent bug (a Kargo 1.11.0 admission-webhook
rejection) surfaced immediately after. Neither was ever logged.

## The incident

1. **Namespace deadlock.** The namespace's Stage resources'
   `kargo.akuity.io/finalizer` could never clear because
   `kargo-webhooks-server` — the pod whose mutating webhook the
   finalizer-removal path calls — had never actually been running (the
   whole `kargo` on-demand unit was undeployed). No controller running →
   finalizer never clears → namespace never finishes deleting → ArgoCD can
   never (re)create the Warehouse in it, forever.
2. **Admission rejection.** Once the controller stack was brought up and
   the namespace finally cleared, Kargo 1.11.0's admission webhook rejected
   the capstone `Warehouse` outright — `imageSelectionStrategy: Digest`
   requires an explicit `constraint`, and the manifest had none.

Both are verified still-current in `gitops/kargo-project/project.yaml`
(the `constraint: latest` fix is live in the file today).

## The fix

Added one row (2026-08-07, **P2**, matching this repo's existing
"on-demand/heavy component broken" classification for Kargo) covering both
findings from the same investigative session, cites the live namespace fix
and PR #1055 (the `constraint` fix), and notes the still-open, separate DNS
follow-up (`harbor.127.0.0.1.nip.io` resolving to a pod's own loopback)
found immediately after — explicitly flagged as unresolved rather than
implied fixed. Added a matching bats coverage test.

`make ci`: green (full local run including real `bats`).

## PR

https://github.com/tooming/k8s-anywhere/pull/1319
