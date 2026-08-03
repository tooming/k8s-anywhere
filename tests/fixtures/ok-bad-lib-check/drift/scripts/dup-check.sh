#!/usr/bin/env bash
# Fixture: a script defining its own local drift-setting bad() — the drift case.
set -uo pipefail
drift=0
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }
bad "example"
exit "$drift"
