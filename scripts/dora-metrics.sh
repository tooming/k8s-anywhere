#!/usr/bin/env bash
# Compute the four DORA metrics (RFC #580) for k8s-lab from git/CI history — no
# live-cluster state involved (ADR-0004: never fabricate what can't be measured).
# Regenerates docs/dora-metrics.md. Clusterless: reads `git log` directly; lead
# time and restore time additionally need the `gh` CLI (GitHub API) — when it
# isn't installed, those two honestly render "insufficient data" rather than
# being silently skipped or estimated.
#
# Implementation correction vs. RFC #580's original text (documented here since
# it's the binding spec an executor reads against): deployment frequency and
# change failure rate use `git log --first-parent`, NOT `--merges`. This repo's
# actual merge convention is squash-merge (WAYS-OF-WORKING.md §3), which produces
# single-parent commits on `main`, not 2-parent merge commits — `--merges` finds
# zero deployments in any window that postdates squash-merge adoption, even
# though real work landed. `--first-parent` correctly counts one integration
# event per PR (squash or legacy true-merge, either style), which is what
# "deployment frequency" actually means here. Lead time similarly can't use
# git-parent diffing against squash history (the original branch's commit
# timestamps aren't preserved — author date == committer date == merge time on
# every squash commit, verified empirically against this repo's own history) —
# it uses the GitHub PR API's createdAt -> mergedAt instead, which survives
# branch deletion.
#
# Shallow-clone correction (found 2026-07-21): this script's only real-world
# caller is the remote executor, which always runs from a freshly shallow-cloned
# container — `git log --first-parent --since=...` against a shallow clone
# doesn't error or fall back to "insufficient data", it silently computes a
# real-but-badly-undercounted number bounded by the clone's shallow boundary
# (observed: a shallow clone whose boundary happened to land 2 days back
# reported "3.97 deployments/week (51 in 90d window)" against a true
# "47.67 deployments/week (613 in 90d window)" from the same repo unshallowed —
# a 12x undercount with no warning, an ADR-0004 risk since the output looks as
# precise and grounded as a real 90-day figure). Fix: detect a shallow clone and
# deepen it before measuring; if deepening fails (no network to the remote),
# render "insufficient data" for the two git-log-derived metrics rather than a
# number the caller can't trust.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1
source "$REPO/scripts/lib/colors.sh"

NOW_EPOCH=$(date +%s)
SINCE_EPOCH="${DORA_SINCE_EPOCH:-$((NOW_EPOCH - 90 * 86400))}"
UNTIL_EPOCH="${DORA_UNTIL_EPOCH:-$NOW_EPOCH}"
BRANCH="${DORA_BRANCH:-main}"
OUT="${DORA_OUT:-docs/dora-metrics.md}"
INSUFFICIENT="insufficient data"

window_days=$(((UNTIL_EPOCH - SINCE_EPOCH) / 86400))
[ "$window_days" -lt 1 ] && window_days=1

# ---- deepen a shallow clone before measuring (see correction note above) ----
GIT_HISTORY_TRUNCATED=0
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
  git fetch --unshallow origin "$BRANCH" >/dev/null 2>&1 || true
  [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && GIT_HISTORY_TRUNCATED=1
fi

iso_utc() {
  date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ
}

median() {
  # reads whitespace-separated numbers on stdin, one per line
  sort -n | awk '{a[NR]=$1} END{if (NR==0) {print ""; exit} if (NR%2==1) print a[(NR+1)/2]; else print (a[NR/2]+a[NR/2+1])/2}'
}

# ---- first-parent commits landing on $BRANCH in the window ------------------
commits_file=$(mktemp)
trap 'rm -f "$commits_file"' EXIT
git log --first-parent "$BRANCH" --since="@$SINCE_EPOCH" --until="@$UNTIL_EPOCH" \
  --format=$'%H\t%ct\t%s' >"$commits_file" 2>/dev/null || true
deploy_count=$(wc -l <"$commits_file" | tr -d ' ')

# ---- Metric 1: Deployment frequency ------------------------------------------
if [ "$GIT_HISTORY_TRUNCATED" -eq 1 ]; then
  M1="${INSUFFICIENT} (shallow clone could not be deepened — window would be truncated)"
elif [ "$deploy_count" -gt 0 ]; then
  weeks=$(awk -v d="$window_days" 'BEGIN{w=d/7; if (w<1) w=1; printf "%.2f", w}')
  freq=$(awk -v c="$deploy_count" -v w="$weeks" 'BEGIN{printf "%.2f", c/w}')
  M1="${freq} deployments/week (${deploy_count} in ${window_days}d window)"
else
  M1="${INSUFFICIENT} (0 commits landed on ${BRANCH} in the window)"
fi

# ---- Metric 3: Change failure rate --------------------------------------------
# A "failure" = (a) a commit message containing "revert", or (b) a `fix:`-style
# commit landing within 72h of an earlier in-window commit that touched at
# least one overlapping file path.
if [ "$GIT_HISTORY_TRUNCATED" -eq 1 ]; then
  M3="${INSUFFICIENT} (shallow clone could not be deepened — window would be truncated)"
elif [ "$deploy_count" -gt 0 ]; then
  failures=0
  while IFS=$'\t' read -r sha ts subj; do
    lc_subj=$(printf '%s' "$subj" | tr '[:upper:]' '[:lower:]')
    case "$lc_subj" in
    *revert*)
      failures=$((failures + 1))
      continue
      ;;
    esac
    case "$subj" in
    fix:* | fix\(*\):*)
      files_now=$(git show --name-only --format= "$sha" 2>/dev/null)
      [ -z "$files_now" ] && continue
      while IFS=$'\t' read -r psha pts _; do
        [ "$psha" = "$sha" ] && continue
        delta=$((ts - pts))
        [ "$delta" -lt 0 ] && continue
        [ "$delta" -gt $((72 * 3600)) ] && continue
        files_prior=$(git show --name-only --format= "$psha" 2>/dev/null)
        [ -z "$files_prior" ] && continue
        if comm -12 <(sort <<<"$files_now") <(sort <<<"$files_prior") | grep -q .; then
          failures=$((failures + 1))
          break
        fi
      done <"$commits_file"
      ;;
    esac
  done <"$commits_file"
  cfr=$(awk -v f="$failures" -v c="$deploy_count" 'BEGIN{printf "%.1f", (f/c)*100}')
  M3="${cfr}% (${failures}/${deploy_count} deployments)"
else
  M3="${INSUFFICIENT} (0 deployments in the window)"
fi

# ---- Metric 2: Lead time for changes (PR createdAt -> mergedAt, needs gh) -----
if command -v gh >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  since_iso=$(iso_utc "$SINCE_EPOCH")
  until_iso=$(iso_utc "$UNTIL_EPOCH")
  pr_json=$(gh pr list --state merged --search "merged:${since_iso}..${until_iso}" \
    --json createdAt,mergedAt --limit 200 2>/dev/null) || pr_json="[]"
  lead_secs=$(printf '%s' "$pr_json" | jq -r '.[] | ((.mergedAt | fromdateiso8601) - (.createdAt | fromdateiso8601))' 2>/dev/null)
  n=$(printf '%s\n' "$lead_secs" | grep -c '^[0-9]' || true)
  if [ "${n:-0}" -gt 0 ]; then
    med=$(printf '%s\n' "$lead_secs" | median)
    med_hrs=$(awk -v s="$med" 'BEGIN{printf "%.1f", s/3600}')
    M2="${med_hrs}h median (n=${n} merged PRs)"
  else
    M2="${INSUFFICIENT} (gh reachable, but 0 merged PRs found in window)"
  fi
else
  M2="${INSUFFICIENT} (gh CLI or jq not available)"
fi

# ---- Metric 4: Time to restore service (main's ci.yml red->green, needs gh) ---
if command -v gh >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  runs_json=$(gh run list --workflow=ci.yml --branch="$BRANCH" --limit 200 \
    --json conclusion,createdAt,updatedAt,status 2>/dev/null) || runs_json="[]"
  restore_secs=$(printf '%s' "$runs_json" | jq -r '
    [.[] | select(.status=="completed")] | sort_by(.createdAt) as $runs
    | reduce range(0; ($runs|length)) as $i
        ({fail_start: null, out: []};
          if $runs[$i].conclusion != "success" then
            .fail_start = (if .fail_start == null then $runs[$i].createdAt else .fail_start end)
          elif .fail_start != null then
            .out += [(($runs[$i].updatedAt | fromdateiso8601) - (.fail_start | fromdateiso8601))]
            | .fail_start = null
          else . end)
    | .out[]' 2>/dev/null)
  n2=$(printf '%s\n' "$restore_secs" | grep -c '^[0-9]' || true)
  if [ "${n2:-0}" -gt 0 ]; then
    med2=$(printf '%s\n' "$restore_secs" | median)
    med2_hrs=$(awk -v s="$med2" 'BEGIN{printf "%.1f", s/3600}')
    M4="${med2_hrs}h median restore time (n=${n2} red→green transitions)"
  else
    M4="${INSUFFICIENT} (gh reachable, but no CI failures found in window)"
  fi
else
  M4="${INSUFFICIENT} (gh CLI or jq not available)"
fi

# ---- render docs/dora-metrics.md ----------------------------------------------
{
  echo "# DORA metrics — k8s-lab"
  echo
  echo "Computed $(iso_utc "$NOW_EPOCH") for the trailing ${window_days}-day window (RFC #580)."
  echo "Regenerate with \`make dora-metrics\`. All four metrics are re-grounded in this"
  echo "repo's clusterless, self-merging GitOps model — see RFC #580 for the full"
  echo "definitions and rationale. A value of \"${INSUFFICIENT}\" means exactly that: not"
  echo "enough evidence existed to compute it, never a fabricated number (ADR-0004)."
  echo
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Deployment frequency | ${M1} |"
  echo "| Lead time for changes | ${M2} |"
  echo "| Change failure rate | ${M3} |"
  echo "| Time to restore service | ${M4} |"
} >"$OUT"

echo "  ${G}✓${Z} wrote ${OUT}"
