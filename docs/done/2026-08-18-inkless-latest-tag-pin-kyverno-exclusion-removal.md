# Pin Aiven Inkless broker `ghcr.io/aiven/inkless:latest` → `:4.2.1-0.46`, remove the Kyverno `disallow-latest-tag` `inkless` carve-out

(CHARTER **Objective O4** admission-policy pre-requisite + **Core Values**
§"Everything as code"; executor-fallback JANITOR pass 2026-08-18, fourth cycle this
run, reached via `executor.prompt.md` STEP 6b after PLANNER/ARCHITECT/DOC-DRIFT-
AUTHOR/TRIAGER all found nothing new this cycle (Now/next fully gated on #631/#633,
unchanged) and UPGRADE-DRAFTER's one-PR-per-run cap was already spent this run
(`upgrade/s3manager-digest-to-v0-8-0`, PR #1214). This cycle's fresh angle: rather
than repeat a currency/coverage sweep, read `gitops/kyverno/policies/disallow-
latest-tag.yaml`'s own header comment for its two remaining exclusions' named flip
conditions (`capstone` — still gated on #631's signed-image confirmation; `inkless`
— "remove the exclusion once ghcr.io/aiven/inkless ships a stable, pinnable named
release tag") and checked whether either had quietly become true. **No
prerequisites — executor may pick up immediately.**

Verified directly (not assumed, ADR-0004): `ghcr.io/v2/aiven/inkless/tags/list`
(673 tags, no pagination — the full list) shows a real `<kafka-version>-<inkless-
build>` numbered release line (e.g. `4.0.0-0.33` through `4.2.1-0.46`, the newest)
now published alongside the rotating `edge`/`edge-<commit>` builds this ADR's
Context section already described when the carve-out was added (2026-07-28) — the
carve-out's own flip condition, satisfied. Checked digests before assuming a
same-content re-pin: `latest`'s manifest digest matched neither `4.2.1-0.46`'s nor
`edge`'s — this is a real version change, not a pin-what's-running no-op like the
demo/s3manager fixes were, called out honestly rather than asserted equivalent.
Inkless is on-demand (`gitops/platform/inkless.yaml` carries no
`syncPolicy.automated`), so this carries zero live-cluster blast radius until a
user next runs `make inkless-up`.

Bumped `gitops/inkless/inkless-statefulset.yaml`'s broker `image:` to
`ghcr.io/aiven/inkless:4.2.1-0.46` with a header-comment note documenting the
finding. Removed `inkless` from `disallow-latest-tag.yaml`'s
`exclude.any[].resources.namespaces` (`[capstone, inkless]` → `[capstone]`) and
marked the carve-out's history section "REMOVED 2026-08-18" (mirroring the
existing argocd-carve-out-removal precedent, issue #999). Updated
`tests/kyverno.bats` (replaced the "excludes the inkless namespace" assertion with
a "no longer excludes" regression guard; the exclude-list-length assertion
`2` → `1`) and `tests/inkless.bats` (a pinned-tag assertion + a no-floating-tag
guard, mirroring this repo's other per-component pin pairs). Updated
`docs/decisions/adr-0015-inkless-diskless-kafka.md`'s Stack table row + a new
Re-evaluation log entry (existing entries kept, appended after — full digest-
comparison finding documented there) and `docs/dependency-register.md`'s Inkless
row "Last reviewed" cell. `make ci` passes.

**ADR-0004 caveat:** this remote clusterless session cannot verify the new image
pulls cleanly and Inkless stays healthy on a live cluster post-bump. Rollback path:
revert the image tag + re-add `inkless` to the Kyverno exclusion list; Inkless is a
plain (not Helm-templated) manifest and an on-demand component, so a revert takes
effect on the next GitOps sync with zero live-cluster blast radius until the next
`make inkless-up`.

## PR

(filled in after PR creation)
