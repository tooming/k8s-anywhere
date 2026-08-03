#!/usr/bin/env bash
# Fixture: a script that sources the shared ok()/bad() instead of defining
# its own copy.
set -uo pipefail
drift=0
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"
ok "clean"
bad "dirty"
exit "$drift"
