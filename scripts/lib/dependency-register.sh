#!/usr/bin/env bash
# Shared docs/dependency-register.md table parser — sourced, not executed.
#
# Extracted 2026-09-02 when a second script (dependency-concentration-sync-check.sh)
# needed the exact same row-enumeration logic dependency-maintenance-check.sh already
# had — mirrors this repo's own established de-duplication pattern (lib/colors.sh's
# skip()/phase(), lib/yq.sh's yqs()): two near-identical copies of a parser is exactly
# the duplication class CLAUDE.md's mechanical-guard principle exists to catch, so this
# was extracted before, not after, a third copy could appear.
#
# depreg_rows(): prints one "<tool>\t<source>" line per real table row from
# docs/dependency-register.md (or $1 if given, for test fixtures), skipping the
# header/divider rows. A comma inside either field (common in the source column,
# e.g. "grafana.com, github.com/...") can't be mistaken for the delimiter since the
# fields are tab-separated, not comma-separated.
depreg_rows() {
  local register="${1:?depreg_rows: register file path required}"
  awk -F'|' '/^\| [A-Za-z(]/{
    t=$2; s=$4;
    gsub(/^ +| +$/,"",t); gsub(/^ +| +$/,"",s);
    if (t != "Tool") print t "\t" s
  }' "$register"
}

# depreg_github_match(): prints the first "OWNER/REPO" substring found in a
# source-column value, or nothing if it has no github.com/OWNER/REPO substring.
# Callers needing just the org (e.g. concentration grouping) can `cut -d/ -f1`;
# callers needing owner+repo separately (e.g. cloning) can `cut -d/ -f1`/`-f2`.
depreg_github_match() {
  printf '%s' "$1" | grep -oE 'github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' | head -1 | cut -d/ -f2-3
}
