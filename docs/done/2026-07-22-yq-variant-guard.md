# Three `make ci` drift detectors silently false-pass when a non-mikefarah `yq` is on PATH

`scripts/helm-chart-pin-check.sh`, `scripts/argocd-crd-ssa-check.sh`, and
`scripts/rollouts-plugin-list-check.sh` all enumerate `kind: Application`
manifests via mikefarah/yq-only syntax (`yq eval-all ...`, and
`rollouts-plugin-list-check.sh`'s `| tag` for YAML-type inspection). Other `yq`
implementations on PATH — this session's own remote container ships python-yq
(kislyuk, a jq wrapper; `yq --version` reports plain `yq 0.0.0`), not
mikefarah/yq — don't recognise `eval-all` as a subcommand and exit non-zero.
All three scripts consume that failure through `2>/dev/null` inside a
`< <(...)` process substitution, so the enumeration loop silently sees zero
records instead of erroring, and each script's own "0 matches" branch reports
a clean "nothing to check" — a **false pass**, not a skip.

Verified directly against this session's real environment (not assumed, per
ADR-0004): `command -v helm` shows nothing; `yq --version` prints `yq 0.0.0`
(no `mikefarah` anywhere in it — confirmed against mikefarah/yq's own
`cmd/version.go` source, which always emits
`"yq (https://github.com/mikefarah/yq/) version vX.Y.Z"`); running
`bash scripts/helm-chart-pin-check.sh` before this fix printed
`✓ no Helm-chart Application pins to verify` even though `gitops/platform/`
has ~30 real chart-bearing Applications — the check was never actually
resolving any of them. `.github/workflows/ci.yml`'s `drift` job installs real
mikefarah/yq (`curl ... github.com/mikefarah/yq/releases/latest/download/...`),
so this gap is invisible in real GitHub Actions CI; it only bites the local
`make ci` run this remote executor performs as its own validation gate,
undermining "make ci passing" as this session's definition of done for every
prior PR that touched a chart pin, CRD-bearing chart, or Rollouts plugin
value — none of those three checks were actually exercised.

## Fix

1. **Fix:** new `scripts/lib/yq-variant.sh` (`require_mikefarah_yq`), mirroring
   the existing "hard-fail in CI, honest skip locally" precedent already used
   inline in these same scripts for a missing `helm`/`jq`. Called at the top
   of all three scripts, before any `yq eval-all`/`yq ea` invocation: if `yq`
   is missing or isn't mikefarah/yq (detected via `yq --version | grep -qi
   mikefarah`), it prints a clear "skipping — not mikefarah/yq" message and
   exits 0 locally, or fails loudly (`exit 1`) when `CI=true`. Real GitHub
   Actions CI is unaffected (`CI=true` + real mikefarah/yq → the guard passes
   through silently, identical behavior to before this fix); this
   environment's local `make ci` run now honestly reports "skipping" instead
   of a fabricated "no pins to verify".
2. **Recurrence guard:** new `scripts/yq-variant-guard-check.sh` (wired into
   `make ci` + `.github/workflows/ci.yml`'s `drift` job, in parity per
   `scripts/ci-parity-check.sh`) — a structural grep asserting every
   `scripts/*.sh` calling mikefarah-only syntax (`yq eval-all`/`yq eval`/
   `yq ea`) also calls `require_mikefarah_yq`, so a future script can't add
   the same unguarded call. Bats coverage in `tests/drift-detectors.bats`
   (in-sync/drift fixtures under `tests/fixtures/yq-variant-guard-check/`) plus
   a "passes on the real repo" case. Also added a companion
   `scripts/yq-variant-guard-sync-hook.sh` (PostToolUse nudge on `scripts/*.sh`
   edits, mirroring `yq-raw-sync-hook.sh`) with its own coverage in
   `tests/hook-scripts-coverage.bats` — **left unwired in
   `.claude/settings.json`'s `PostToolUse` array**: this session's Edit tool
   call adding that block was denied by the harness (a per-session tool
   constraint, not a repo policy — CLAUDE.md is explicit that such
   constraints "are not repo-configurable"). The CI gate (Makefile +
   `ci.yml`, both green) is the binding, mechanical enforcement either way;
   the hook is a local nudge only. A future interactive session (or the
   maintainer) can complete the wiring by adding a `yq-variant-guard-sync-hook.sh`
   entry to the `Edit|Write|MultiEdit` hooks array, matching the
   `yq-raw-sync-hook.sh` entry immediately above it.

No topology change — no README/`docs/dependency-tree.md` update needed.
`make ci` passes locally (all real checks green; `bats`/`shellcheck`/
`kubeconform`/`kustomize`/`terraform`/`helm` gracefully skip as designed —
none installed in this environment).

## PR

https://github.com/tooming/k8s-anywhere/pull/662
