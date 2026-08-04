# Chaos / fault-injection drill — `make dr-chaos`

(CHARTER **Goals** §"operational-resilience discipline" + §"DR / blue-green on a
single host" — DORA's Pillar 3 "digital operational resilience testing" (TLPT —
threat-led penetration testing — concept); planner-fallback gap analysis 2026-08-04,
reached via `executor.prompt.md` STEP 6b after all three standing "Now / next" items
were found gated on unconfirmed maintainer-confirmation issues #631/#633 with no
live-state-safe slice to split off. **No prerequisites — executor may pick up
immediately.**) Verified directly (not assumed, ADR-0004): `docs/dora-audit-readiness.md`'s
Q12 ("Is there an adversarial/penetration-style test (DORA's TLPT concept)?") answered
"No fault-injection or chaos-engineering scenario exists... the closest analog —
blue/green cutover — tests *planned* failover, not an *injected* failure" and its own
"Gap" line named the exact scoped fix: "a `make dr-chaos` that kills a random capstone
pod during `make capstone-demo` and asserts the Rollout/ArgoCD self-heals within
budget." Grepping ROADMAP.md for "chaos"/"fault-inject" turned up nothing already
tracking this. This was real gap-analysis output the audit doc itself flagged as "a
reasonable, scoped future ROADMAP item if you want to close it."

Added `scripts/dr-chaos.sh` mirroring `scripts/dr-restore.sh`'s style (sources
`lib/colors.sh` + `lib/budget-check.sh`). Picks one running capstone pod at random
using bash's built-in `$RANDOM` (not `shuf`, to avoid an external-tool dependency),
deletes it, then polls until the pod count is back to its pre-injection value or the
120s budget is exceeded. Budget justified against `gitops/apps/capstone/rollout.yaml`'s
actual shape: a single replica (no HA, ADR-0005), no `progressDeadlineSeconds`
override, so recovery is just schedule + already-cached-image + container start —
normally well under 30s on a healthy node; 120s gives 4x headroom without masking a
real regression. Followed `dr-destroy.sh`'s confirmation-prompt precedent
(`DR_ASSUME_YES=1` bypass for non-interactive use, typed confirmation otherwise) since
this deletes a live pod. Added the `dr-chaos` Makefile target (on-demand only —
verified not wired into `up`, `ci`, or `dr-test`'s own block). New `tests/dr-chaos.bats`
(clusterless structural, mirrors `tests/dr-bluegreen.bats`'s shape): script
existence/executable, lib sourcing, `BUDGET_S` constant, confirmation guard, no `shuf`
dependency, Makefile wiring, and "not invoked from on-demand-only targets" assertions
— every assertion verified by hand against the real files before committing. Added a
new "Chaos / fault-injection drill" subsection to `docs/DR.md` (after the blue/green
section) explaining the mechanism, the budget reasoning, and that this introduces no
new failure mode — pod-delete-then-recreate is a guarantee Kubernetes' ReplicaSet
controller already provides; the drill only observes and times it. Updated
`docs/dora-audit-readiness.md`'s Q12 answer accordingly, narrowing (not closing) its
residual gap to other fault types (NetworkPolicy cuts, Garage unavailability) the
question's original framing named, and keeping the ADR-0004 caveat that this
clusterless session authored and structurally verified the script but did not execute
it against a real cluster.

**Deviation from the ROADMAP item's illustrative numbers, with reasoning:** the item's
own body offered "e.g. 300s" and `shuf` only as illustrative starting points and
explicitly required verifying against the Rollout's actual shape rather than guessing
— did that verification and landed on 120s (justified above) and `$RANDOM`+`sed`
instead of `shuf` (avoids depending on a tool not guaranteed present, exactly the
alternative the item's own body flagged as acceptable ["...or the active ReplicaSet's
pod if `shuf` isn't guaranteed available — check"]).

`make ci` passed locally (lint/readme-check/lab-ui-check/roadmap-check/
markdown-links-check/drift checks green; the usual cluster-tool checks skip in this
clusterless sandbox and the bats suite — including the new `tests/dr-chaos.bats` —
runs for real in GitHub Actions). Zero live-cluster blast radius from this PR itself
(the script exists and is structurally tested but was not executed against a cluster
this session).

## PR

https://github.com/tooming/k8s-anywhere/pull/975
