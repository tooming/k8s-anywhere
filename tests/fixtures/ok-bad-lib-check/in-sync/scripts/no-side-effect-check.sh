#!/usr/bin/env bash
# Fixture: a script that legitimately keeps its own no-side-effect bad()
# (tracks failure via a separately-managed `fail` variable instead) — must
# NOT be flagged by the drift-setting-only guard.
set -uo pipefail
fail=0
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; }
bad "example"; fail=1
exit "$fail"
