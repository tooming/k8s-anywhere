# Shared retry_cmd() for .forgejo/workflows/build-sign-push.yml's
# network-facing steps — sourced, not executed.
#
# Extracted 2026-08-20 (janitor-fallback cleanup, `executor.prompt.md` STEP 6b):
# this exact function body was duplicated verbatim across three separate
# steps in that workflow (build-and-push's "Login to Harbor" and "Build, tag,
# and push", plus sign-image's "Sign the pushed image") — the same
# shape scripts/lib/colors.sh's own extraction comment already documents for
# 15+ scripts (issue #957). The duplication already cost real time once: PR
# #1276 bumped the retry budget (max=6/delay=15 -> max=14/delay=30) and left
# stale commentary behind in one of the two build-and-push copies, requiring
# a follow-up fix (PR #1277) to notice and correct it. A single shared
# definition makes that class of drift impossible for the two steps that can
# source it (see below).
#
# NOT sourced by sign-image's own copy: that job runs in a separate container
# with no checkout step (it only writes the cosign key and signs — it never
# needed repo files before), so this file isn't on disk there. Adding a
# checkout step there purely to source this file would be a behavior change
# to a pipeline still under active live-tuning (issue #633), out of scope for
# a bounded, behavior-preserving cleanup — left as a documented follow-up,
# not attempted here. sign-image's inline copy must still be kept
# byte-identical to this one by hand until that follow-up lands.
#
# max=14/delay=30 (~6.5 minutes of budget): Harbor's core/registry containers
# run under QEMU x86_64 emulation on this arm64 host and crash under real
# sustained push/read I/O (see gitops/platform/harbor.yaml's own
# GOMAXPROCS/GODEBUG comments); observed live recovery time from a crash back
# to genuinely stable was routinely 2-4+ minutes, not seconds (found live
# 2026-08-19, issue #633 verification).
retry_cmd() {
  local n=0 max=14 delay=30
  until "$@"; do
    n=$((n+1))
    [ "$n" -ge "$max" ] && { echo "retry_cmd: giving up after $n attempts: $*" >&2; return 1; }
    echo "retry_cmd: attempt $n failed, retrying in ${delay}s: $*" >&2
    sleep "$delay"
  done
}
