#!/usr/bin/env bash
# Validate the Terraform under infra/: formatting (offline), then per-module
# `terraform validate` (needs the provider registry) and tflint. Catches a broken
# module before it blows up mid-`make up` on the day-0 critical path.
#
# `terraform fmt` and tflint work offline and are always enforced. `terraform
# validate` needs to download providers; if the registry is unreachable it's a
# hard failure under CI (CI=true) but a soft skip locally, so offline dev isn't
# blocked.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
drift=0
source "$(dirname "${BASH_SOURCE[0]}")/lib/colors.sh"

printf '%s== validate terraform ==%s\n' "$B" "$Z"

if ! command -v terraform >/dev/null 2>&1; then
  if [ "${CI:-}" = "true" ]; then bad "terraform not installed (required in CI)"; exit 1; fi
  skip "terraform not installed — skipping (install to validate locally)"; exit 0
fi

# --- 1. formatting (offline, whole tree) ------------------------------------
if terraform fmt -check -recursive infra/ >/dev/null 2>&1; then
  ok "terraform fmt: clean"
else
  bad "terraform fmt: needs formatting (run: terraform fmt -recursive infra/)"
  terraform fmt -check -recursive infra/ || true
fi

# --- 2. per-module validate (needs provider registry) -----------------------
for mod in infra/modules/*/; do
  [ -f "$mod/main.tf" ] || continue
  name="$(basename "$mod")"
  if ! terraform -chdir="$mod" init -backend=false -input=false >/tmp/tfinit.log 2>&1; then
    if [ "${CI:-}" = "true" ]; then
      bad "module '$name': terraform init failed"; sed 's/^/      /' /tmp/tfinit.log | tail -8
    else
      skip "module '$name': init failed (provider registry unreachable?) — skipping validate"
    fi
    continue
  fi
  if terraform -chdir="$mod" validate -no-color >/tmp/tfval.log 2>&1; then
    ok "module '$name': terraform validate"
  else
    bad "module '$name': terraform validate failed"; sed 's/^/      /' /tmp/tfval.log | tail -12
  fi
done

# --- 3. tflint (bundled terraform ruleset, offline) -------------------------
if command -v tflint >/dev/null 2>&1; then
  for mod in infra/modules/*/; do
    [ -f "$mod/main.tf" ] || continue
    name="$(basename "$mod")"
    if tflint --chdir="$mod" --no-color >/tmp/tflint.log 2>&1; then
      ok "module '$name': tflint"
    else
      bad "module '$name': tflint"; sed 's/^/      /' /tmp/tflint.log | tail -12
    fi
  done
else
  if [ "${CI:-}" = "true" ]; then bad "tflint not installed (required in CI)"; else skip "tflint not installed — skipping"; fi
fi

echo
[ "$drift" -eq 0 ] && printf '%s%sterraform: PASS%s\n' "$B" "$G" "$Z" || printf '%s%sterraform: FAIL%s\n' "$B" "$R" "$Z"
exit "$drift"
