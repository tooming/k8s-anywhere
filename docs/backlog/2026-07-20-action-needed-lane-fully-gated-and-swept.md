# [Action needed] Now/next fully gated; a thorough same-run sweep found nothing new

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on a
**maintainer-confirmation prerequisite this remote clusterless session cannot
satisfy** (live-cluster state a human must observe and confirm):

1. **verifyImages ClusterPolicy — Audit → Enforce flip** — needs the maintainer
   to confirm at least one CI run pushed a `.sig` tag to Artifactory
   (`curl http://artifactory.127.0.0.1.nip.io:8000/artifactory/docker-local/hello/.sig`
   returns 200).
2. **O4 CI gate — `verify-image-rejection` job** — depends on item 1 merging
   first.
3. **Capstone pipeline re-wire — Artifactory → Harbor** — needs the maintainer
   to confirm on issue/RFC #297 that the minimal Harbor profile was measured
   on the live cluster and fits the 12 GB budget (the ADR-0024 go/no-go gate).
4. **Decommission Artifactory manifests** — depends on item 3 merging first.
5. **Remove legacy capstone `Deployment`** — needs the maintainer to confirm
   the Argo Rollouts canary pipeline has been exercised end-to-end on the live
   cluster (at least one successful Kargo promotion seen).

None of the five has a live-state-safe slice left to split out per ROADMAP
rule #9 — each is already the final, non-splittable gated slice of its own
RFC (verified this run, same conclusion as the run's earlier cycles).

## What this run already did instead (6 real PRs, 2 RFCs, before this note)

Rather than stop at the gated lane, this run worked the STEP 6b fallback
chain repeatedly and landed real work each time:

- RFC #611 (architect) → groomed → **PR #614**: bumped `actions/checkout`,
  `actions/cache`, `actions/github-script`, `hashicorp/setup-terraform` to
  their Node-24 majors.
- **PR #615** (upgrade-drafter): Argo Rollouts chart `2.41.0` → `2.41.1`,
  fulfilling ADR-0020's own recorded flip condition (CVE-2026-35469).
- **PR #616** (janitor): synced ADR-0020 + `docs/dependency-tree.md`'s
  now-stale version references left over from PR #615.
- RFC #617 (architect) → groomed → **PR #620**: bumped Velero's chart
  `8.7.2` → `12.1.0` (4 majors), fulfilling ADR-0021's own recorded flip
  condition, after directly verifying the values-schema this repo actually
  uses is unchanged across the jump.

## This cycle's sweep (found nothing new)

A repeat pass, deliberately using a **different lens** each time (per STEP 8):
zero open GitHub issues; `docs/roadmap/incoming/` empty; re-checked every ADR
with a documented `Flip condition` (ADR-0006, 0008, 0009, 0012, 0013, 0016,
0017, 0019, 0020, 0021, 0023, 0028) against real upstream state — all either
already resolved this run or genuinely unmet (e.g. RabbitMQ/Longhorn's flip
conditions are EOL-window triggers, not yet reached; cert-manager/Envoy
Gateway/Istio/Kyverno/Argo CD flip conditions are new-bulletin triggers, none
found above the current pins). Walked every semver-pinned chart across
`gitops/**/*.yaml` via `git ls-remote --tags` against the real upstream repo
(not inferred) — every one is already at its latest stable release except
Artifactory (deliberately skipped: it's mid-decommission per items 3–4 above,
so bumping it is conflicting churn, not progress). No `make ci` doc-drift
signal (readme-check / lab-ui-check both clean).

## What would unblock the gated lane

Any of: (a) the maintainer confirming a live-cluster observation for items 1
or 3 above; (b) a new upstream CVE/release that fires one of the ADRs' flip
conditions (this run's own sweep found none as of 2026-07-20); (c) a new
GitHub issue describing further work of any size (the planner sizes it next
cycle).

This note is this cycle's honest record, not a stopping point — the run
continues to the next cycle per `executor.prompt.md` STEP 8.
