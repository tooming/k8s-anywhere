#!/usr/bin/env bash
# Structural check: does an "executor/session idle — no work" GitHub issue (or
# comment) document the full-fallback-chain evidence ROADMAP rule #9 requires,
# before anyone tells the maintainer no work exists? Takes TITLE + BODY via env
# vars (or $1/$2) so it is directly bats-testable without a real GitHub payload.
#
# Recurrence this guards against: a session hits a blocked "Now / next" item and
# reports "nothing to do" without (a) actually running the clusterless `make ci`
# gate to rule out doc/dashboard drift, and (b) diffing CHARTER.md's Objectives
# against ROADMAP.md's checked items to rule out an un-groomed gap. Both are
# real, clusterless, always-available checks — "idle" must mean both came back
# clean, not "the first blocked item I looked at was blocked."
set -uo pipefail

TITLE="${IDLEGUARD_TITLE:-${1:-}}"
BODY="${IDLEGUARD_BODY:-${2:-}}"
TEXT="$TITLE
$BODY"

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

# Not an idle/no-work declaration -> nothing to check.
printf '%s' "$SCRUBBED" | grep -qiE '\bidle\b|\bno work\b|nothing to do|no actionable' || exit 0

missing=""
printf '%s' "$BODY" | grep -qi 'make ci' \
  || missing="${missing}  - no mention of running \`make ci\` (rules out doc/dashboard drift)
"
printf '%s' "$BODY" | grep -qi 'CHARTER' \
  || missing="${missing}  - no mention of cross-checking CHARTER.md's Objectives against ROADMAP.md (rules out an un-groomed gap)
"

if [ -n "$missing" ]; then
  echo "Idle claim is missing required fallback-chain evidence (ROADMAP rule #9):"
  printf '%s' "$missing"
  echo "Before telling the maintainer there is no work: run \`make ci\` and diff CHARTER.md's Objectives against ROADMAP.md's checked items, then document both results in the issue body."
  exit 1
fi
exit 0
