#!/usr/bin/env bash
# Fixture: a script using mikefarah-only yq syntax, correctly guarded.
set -uo pipefail
require_mikefarah_yq "guarded-check"
yq eval-all '.foo' file.yaml
