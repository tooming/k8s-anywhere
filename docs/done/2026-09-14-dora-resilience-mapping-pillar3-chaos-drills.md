# DORA resilience mapping — cite the dr-chaos-*.sh drills in Pillar 3

## What

`docs/dora-resilience-mapping.md`'s Pillar 3 section ("Digital operational
resilience testing") cited only `make dr-verify` and `make dr-test` as
evidence, and separately noted the removal of `make dr-bluegreen`. It made
no mention at all of the four `dr-chaos-*.sh` fault-injection drills
(`dr-chaos-argocd.sh`, `dr-chaos-cert-manager.sh`, `dr-chaos-traefik.sh`,
`dr-chaos-lab-demo.sh`) added 2026-09-11/12 specifically to close
`docs/dora-audit-readiness.md`'s Q12 gap — a real content gap, since
fault injection is squarely what DORA's Pillar 3 concept (and Q10/Q12 of
the audit-readiness doc) is about.

## Why it matters

`dora-resilience-mapping.md` exists to give an accurate lens onto what
this lab's actual practices map to under DORA's five pillars (RFC #586,
explicitly non-compliance-claiming). Omitting an entire drill category
that exists today and was added for exactly this purpose understates the
lab's Pillar 3 coverage and would mislead a reader comparing this doc
against `docs/dora-audit-readiness.md`'s own (accurate, already-updated)
Q10/Q12 answers.

## Fix

Added a paragraph to the Pillar 3 section citing all four `dr-chaos-*.sh`
drills, their `make` targets, their add dates, and their per-component
recovery predicates — reusing the exact phrasing/dating convention already
established in `docs/dora-audit-readiness.md`'s Q12 answer, and explicitly
repeating that this is not a TLPT-style adversarial/penetration test (no
attack simulation, no red-team methodology), matching Q12's own framing.
Left the existing `dr-verify`/`dr-test`/removed-`dr-bluegreen` content
untouched — only added the missing citation.

## Verification

- Read `docs/dora-resilience-mapping.md` in full (96 lines) before editing;
  confirmed no other section already covers the chaos drills.
- `grep -n "dr-chaos" docs/dora-audit-readiness.md` — confirmed the
  established phrasing/dating convention (`added 2026-09-11`/
  `added 2026-09-12`, per-drill recovery-predicate descriptions) reused
  verbatim in this edit.
- `make ci` — full clusterless suite (bats, kustomize, kubeconform,
  terraform, ~40 drift-detector scripts including doc-sync checks) —
  green.

## PR

_placeholder — backfilled after PR creation_
