#!/usr/bin/env bash
# Structural check: is anyone about to file/comment an "executor/session idle —
# no work" GitHub issue? That outcome is now forbidden outright (ROADMAP rule
# #9, revised 2026-07-14) — every run ships a PR, no exceptions. Takes TITLE +
# BODY via env vars (or $1/$2) so it is directly bats-testable without a real
# GitHub payload.
#
# History: this script used to *require evidence* (a `make ci` run + a
# CHARTER-vs-ROADMAP diff) before allowing an idle issue through. That let
# idle issues accumulate anyway (#52, #56, #57, #76, #89, #121, #262, #390,
# #398) instead of forcing a PR. The maintainer ended the whole pattern
# (2026-07-14): idle declarations are blocked unconditionally now, not merely
# evidence-gated. ROADMAP rule #9's fallback chain (doc-drift, CHARTER gap,
# architect RFC, triage, coverage/hardening sweep, split-the-gate) always has
# a real, clusterless, gate-passing item somewhere in it — that's what a
# blocked run must produce instead.
set -uo pipefail

TITLE="${IDLEGUARD_TITLE:-${1:-}}"
BODY="${IDLEGUARD_BODY:-${2:-}}"
STATE="${IDLEGUARD_STATE:-${3:-}}"
TEXT="$TITLE
$BODY"

# Closing an issue is the resolution, never the violation — an update that sets
# state=closed is always allowed through regardless of what its body discusses
# (e.g. "closing this idle issue per the new policy" legitimately contains the
# word "idle" while doing exactly what the policy requires). Only a call that
# leaves/creates the issue open is a candidate idle *declaration*.
[ "$STATE" = "closed" ] && exit 0

# Strip any "idle-<word>" compound (idle-titled, idle-flavored,
# idle-issue-guard-check.sh, ...) before pattern-matching — a PR or comment
# that merely *discusses* this feature (as any future change to this very
# script will) must not self-trigger just for naming it or its own script
# files. Caught empirically: the [self-review] comment on the PR that
# introduced this guard tripped over its own filenames and "idle-titled".
# Real idle declarations use "idle" as a standalone word ("executor idle —
# needs work", "session is idle") — never as a hyphenated compound — so this
# scrub only removes the false-positive shape.
# Portability: `\b` (word boundary) is a GNU sed extension that BSD/macOS
# sed's POSIX ERE mode doesn't support — it silently fails to match at all
# there, making this a no-op on macOS while working fine on CI's Ubuntu
# runners. `(^|[^A-Za-z0-9_-])` + back-reference is the portable equivalent
# (also drops the GNU-only `I` flag; real "idle-" compounds are lowercase).
SCRUBBED="$(printf '%s' "$TEXT" | sed -E 's/(^|[^A-Za-z0-9_-])idle-[A-Za-z.-]+/\1/g')"

# Not an idle/no-work declaration -> nothing to block.
printf '%s' "$SCRUBBED" | grep -qiE '\bidle\b|\bno work\b|nothing to do|no actionable' || exit 0

cat <<'EOF'
BLOCKED: "executor/session idle — no work" declarations are forbidden (ROADMAP
rule #9, revised 2026-07-14). Do not file this issue or post this comment.

Every run ships a PR — walk ROADMAP rule #9's fallback chain instead and build
whatever it turns up: doc-drift (make ci), a CHARTER-vs-ROADMAP gap, an unRFC'd
🟡 item, issue triage, a test-coverage/docs-accuracy/dependency-pin hardening
sweep, or splitting a maintainer-confirmation-gated item into an ungated
sub-slice. One of these is always real, clusterless, gate-passing work.
EOF
exit 1
