#!/usr/bin/env bash
# Fixture: a script using mikefarah-only yq syntax with no guard — the drift case.
set -uo pipefail
yq eval-all '.foo' file.yaml
