#!/usr/bin/env bash
# ADR image-pin sync check: some ADRs pin a plain container image tag inline
# in their Decision prose ("A pinned official `<image>:<tag>` image") instead
# of a Helm chart targetRevision — RabbitMQ (ADR-0009) is the first example,
# since it's deployed via a plain StatefulSet, not a chart (ADR-0009 §"Plain
# manifests over a Helm chart / operator"). That inline mention is a live
# mirror of gitops/data/rabbitmq/statefulset.yaml's actual image tag, same
# self-tracking-note category as the "Chart + version" pattern
# scripts/adr-chart-version-sync-check.sh already guards — and the same
# recurrence class that check exists to prevent (PR #616: an ADR's
# self-tracking note going stale after a version bump landed without it,
# caught only by a manual planner pass). This guard makes that impossible for
# the image-pin phrasing too: it discovers every ADR using the phrasing (no
# hardcoded list — self-maintaining as new ADRs adopt the same convention),
# locates the StatefulSet/Deployment manifest from the ADR's own "## Files"
# table, and asserts the two tags match.
#
# ADR-0018 (Valkey) is the second example, and it went stale exactly the way
# this guard exists to prevent: a CVE-driven bump (8.0-alpine -> 8.0.10-alpine,
# PR #658) was correctly recorded in ADR-0018's own Re-evaluation log but left
# the "Plain manifests over a Helm chart" section's inline mention on the old
# tag — caught by a 2026-08-12 executor sweep and fixed by adding "official" to
# match this script's phrasing (accurate: valkey/valkey is the project's real
# official image), so this guard now covers it too (self-maintaining, no code
# change needed here).
#
# Run by `make adr-image-pin-sync-check`, the CI 'drift' gate, and the
# PostToolUse hook. Exit 0 = every self-tracking image-pin ADR matches its
# live manifest; 1 = drift found.
set -uo pipefail
# ROOT defaults to the repo; tests point ADRIMAGEPINCHECK_ROOT at a fixture tree.
ROOT="${ADRIMAGEPINCHECK_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

ADR_DIR="$ROOT/docs/decisions"
if [ ! -d "$ADR_DIR" ]; then
  echo "no docs/decisions/ — nothing to check"
  exit 0
fi

drift=0
found=0
printf '%s== ADR image-pin sync ==%s\n' "$B" "$Z"
for adr in "$ADR_DIR"/adr-*.md; do
  [ -f "$adr" ] || continue

  # Match "A pinned official `<image>:<tag>` image" (the RabbitMQ/ADR-0009
  # phrasing). image_ref e.g. "rabbitmq:4.3.3-management".
  image_ref="$(grep -oE 'pinned official `[^`]+`' "$adr" | head -1 | sed -E 's/pinned official `([^`]+)`/\1/')"
  [ -n "$image_ref" ] || continue
  found=1

  name="$(basename "$adr")"
  image_name="${image_ref%:*}"
  adr_tag="${image_ref##*:}"

  # Locate the live manifest from the ADR's own "## Files" table (the
  # section between the "## Files" heading and the next "##" heading): the
  # first backtick-quoted gitops path whose filename looks like a workload
  # manifest (statefulset/deployment/daemonset — where an `image:` tag
  # would actually live), not e.g. the ArgoCD Application root file.
  files_section="$(awk '/^## Files/{f=1;next} f && /^## /{exit} f' "$adr")"
  gitops_file="$(printf '%s\n' "$files_section" \
    | grep -oE '`gitops/[^`]+\.ya?ml`' | tr -d '`' \
    | grep -iE '/(statefulset|deployment|daemonset)\.ya?ml$' | head -1)"

  if [ -z "$gitops_file" ]; then
    bad "$name: 'pinned official ... image' phrasing found but no StatefulSet/Deployment row in its Files table — check the Files section's format"
    continue
  fi

  gitops_path="$ROOT/$gitops_file"
  if [ ! -f "$gitops_path" ]; then
    bad "$name: Files table references missing manifest $gitops_file"
    continue
  fi

  live_tag="$(grep -oE "image: ${image_name}:[^[:space:]]+" "$gitops_path" | head -1 | sed -E "s#image: ${image_name}:##")"
  if [ -z "$live_tag" ]; then
    bad "$name: couldn't find an 'image: ${image_name}:...' line in $gitops_file to compare against"
    continue
  fi

  if [ "$live_tag" = "$adr_tag" ]; then
    ok "$name: pinned image ($image_name:$adr_tag) matches $gitops_file's live tag"
  else
    bad "$name: says pinned image is \"$image_name:$adr_tag\" but $gitops_file's live tag is \"$image_name:$live_tag\" — update the ADR's Decision prose (and Re-evaluation log) to match the live pin"
  fi
done

if [ "$found" -eq 0 ]; then
  ok "no ADR uses the self-tracking 'pinned official ... image' phrasing"
fi

echo
[ "$drift" -eq 0 ] && printf '  %s✓%s every self-tracking ADR image-pin note matches its live manifest\n' "$G" "$Z"
exit "$drift"
