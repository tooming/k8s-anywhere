#!/usr/bin/env bash
# yq-variant-robust scalar extraction for bats tests.
#
# yq implementations disagree on how they print scalar output: mikefarah yq
# prints them raw (250m), while python-yq (a jq wrapper) JSON-quotes them
# ("250m"). A bare `$(yq …)` consumed by a numeric/string comparison silently
# breaks on whichever variant is on PATH — this is exactly the cpu_millis
# regression in argocd-resources.bats, where a container yq returned "250m" and
# crashed the millicore arithmetic ("250m" * 1000 → syntax error).
#
# Always read scalars through yqs() so a test never has to care which yq is
# installed. It strips one layer of surrounding double quotes, normalising both
# variants to raw output. The scripts/yq-raw-check.sh drift gate enforces that no
# bats test calls a bare `yq` and bypasses this helper.
yqs() {
  local out rc
  out="$(yq "$@")"; rc=$?
  [ "$rc" -eq 0 ] || return "$rc"
  out="${out%\"}"   # strip trailing quote, if any
  out="${out#\"}"   # strip leading quote, if any
  printf '%s\n' "$out"
}

# require_mikefarah_yq_or_skip(): bats-flavored counterpart to
# scripts/lib/yq-variant.sh's require_mikefarah_yq() — for tests whose yqs() call
# uses syntax/semantics yqs()'s quote-stripping can't normalise across variants
# (mikefarah-only operators like `| tag`; chained field access through a scalar,
# which python-yq treats as a type error instead of null; a scalar containing
# literal double quotes, which python-yq JSON-escapes and yqs() doesn't unescape).
# Call it inside the specific @test body (or a file's setup(), if every test in
# that file exercises a script gated by require_mikefarah_yq()) that needs it —
# never blanket-applied, so a test whose yqs() call IS variant-safe still runs
# and still catches a real regression under any yq.
#
# Without this, the wrong yq variant doesn't just fail these tests loud — for a
# script wrapped by require_mikefarah_yq() (helm-chart-pin-check.sh,
# argocd-crd-ssa-check.sh, rollouts-plugin-list-check.sh), its own "skip, don't
# fail" exit 0 makes a bats assertion checking only `[ "$status" -eq 0 ]` report a
# false pass — the test looks green without the check's logic having run at all.
# CI always installs real mikefarah/yq (.github/workflows/ci.yml), so neither
# failure mode fires there; this only helps a local run tell "skipped, install
# mikefarah/yq" apart from "failed" or a silent false-pass.
require_mikefarah_yq_or_skip() {
  yq --version 2>&1 | grep -qi mikefarah || skip "requires mikefarah/yq on PATH (see scripts/lib/yq-variant.sh)"
}
