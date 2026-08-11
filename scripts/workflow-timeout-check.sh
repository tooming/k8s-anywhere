#!/usr/bin/env bash
# GitHub/Forgejo Actions workflow timeout check: every job in .github/workflows/*.yml
# AND .forgejo/workflows/*.yml must set an explicit `timeout-minutes:`. Without one,
# GitHub Actions' 360-minute default job timeout applies -- a network-dependent step
# that hangs instead of failing blocks a run for hours with no automatic recovery,
# observed directly on PR #648 (2026-07-21, ci.yml's `unit`/`drift` jobs sat
# in_progress 20+ minutes with zero progress across three attempts). ci.yml itself
# already applies this lesson to all six of its own jobs (see its own header comment)
# -- this check makes sure it stays applied there AND propagates to every other
# workflow file, after five of them were found missing it entirely (2026-08-07
# janitor sweep, including an hourly-cron job where a hang could otherwise strand a
# runner for up to 6 hours). .forgejo/workflows/ joined the scope once the ADR-0035
# migration added one (build-sign-push.yml) -- the same failure mode applies there
# too, and arguably worse: unlike GitHub's fleet of ephemeral hosted runners, this
# lab's forgejo-runner is a single long-lived container (forgejo/docker-compose.yml)
# a hung job strands the *only* runner, blocking every subsequent CI run until
# someone notices and restarts it, not just one job slot. Runs in CI (the 'drift'
# job) and via `make ci`. Exit 0 = every job has a timeout; 1 = at least one doesn't.
set -uo pipefail
ROOT="${WORKFLOWTIMEOUTCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
drift=0
found_any=0

for WF_DIR in "$ROOT/.github/workflows" "$ROOT/.forgejo/workflows"; do
  [ -d "$WF_DIR" ] || continue
  found_any=1
  for f in "$WF_DIR"/*.yml "$WF_DIR"/*.yaml; do
    [ -f "$f" ] || continue
    # Each top-level job (two-space indent, "<name>:") starts a job block; collect
    # every job name, then confirm each one's block (up to the next same-indent
    # job or EOF) contains a timeout-minutes: key.
    jobs="$(awk '
      /^jobs:/ { injobs=1; next }
      injobs && /^  [a-zA-Z0-9_-]+:[ \t]*$/ {
        line=$0
        sub(/^  /, "", line)
        sub(/:.*/, "", line)
        print line
      }
      injobs && /^[a-zA-Z]/ { injobs=0 }
    ' "$f")"
    for j in $jobs; do
      # Extract this job's block: from its "  <j>:" line to the next top-level-job
      # line (2-space indent + word + colon) or EOF.
      block="$(awk -v job="  $j:" '
        $0 == job { infound=1; print; next }
        infound && /^  [a-zA-Z0-9_-]+:[ \t]*$/ { exit }
        infound { print }
      ' "$f")"
      grep -q 'timeout-minutes:' <<<"$block" || bad "$(basename "$f") job '$j' has no timeout-minutes -- defaults to GitHub Actions' 360-minute ceiling on a hang"
    done
  done
done

[ "$found_any" -eq 1 ] || { echo "no .github/workflows/ or .forgejo/workflows/ -- nothing to check"; exit 0; }
[ "$drift" -eq 0 ] && ok "every .github/workflows/*.yml and .forgejo/workflows/*.yml job sets an explicit timeout-minutes"
exit "$drift"
