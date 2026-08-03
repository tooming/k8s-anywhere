#!/usr/bin/env bash
# Fixture: a script that sources the shared yqs() helper instead of defining
# its own copy.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/yq.sh"
yqs '.foo' file.yaml
