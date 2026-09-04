# Fix a silent correctness bug in mimir-readonly-root-check.sh + close its test gaps

Continuing ROADMAP rule #9's coverage/hardening sweep, writing fixtures for
`scripts/mimir-readonly-root-check.sh`'s three previously-untested failure branches
(zero writable volumeMounts; ConfigMap missing `data["mimir.yaml"]`; a required
setting present but pointed at a non-writable mount) surfaced a real bug in the first
branch, not just a coverage gap.

## The bug

`mapfile -t WRITABLE < <(python3 ... print('\n'.join(mounts)))` — when `mounts` is an
empty list, `'\n'.join([])` is `''`, but `print('')` still emits one newline. `mapfile`
reads that as **one empty-string array element** (`${#WRITABLE[@]}` is 1, not 0), not
zero elements. Two consequences, both silent:

1. The dedicated `[ "${#WRITABLE[@]}" -eq 0 ]` early-exit (meant to catch "the
   Deployment has no writable mounts at all") never fires — dead code.
2. Worse: `under_writable()`'s glob match `"$m"/*` with `m=""` becomes the literal
   pattern `/*`, which matches **every** absolute path. So a Mimir Deployment that
   accidentally lost all its `emptyDir`/PVC volume mounts would have every write path
   reported `✓ ... is on a writable mount` — the exact false-negative this guard exists
   to prevent (per its own header comment: Mimir already CrashLoopBackOff'd for days
   from this class of misconfiguration once).

Verified directly: a fixture Deployment with only a configMap-backed mount (no
emptyDir/PVC) passed with 100% false "✓" output before the fix; `bash -c` isolating the
glob confirmed `case "/etc/mimir/anything" in ""/*) ;;` matches.

## Fix + guard

- `scripts/mimir-readonly-root-check.sh`: only `print()` the joined mount list when
  `mounts` is non-empty, so zero real writable mounts produces zero bytes of output —
  `mapfile` then correctly gives a zero-length array.
- New `tests/fixtures/mimir-readonly-root-check/{no-writable-mounts,no-configmap-data,
  required-not-writable,arbitrary-path-not-writable}/` fixture trees.
- Four new `tests/drift-detectors.bats` assertions covering each branch, including a
  named regression test for the bug above.

`make ci` passes (same 7 pre-existing environment-only failures as prior PRs this
session). The real repo's actual Mimir manifests still pass the check unchanged.

## PR

https://github.com/tooming/k8s-anywhere/pull/403
