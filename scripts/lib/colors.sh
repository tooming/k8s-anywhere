# Shared ANSI color setup for scripts/*.sh output — sourced, not executed.
# Duplicated identically (or as a same-behavior subset) across 15+ scripts before
# this extraction; consolidated so a future style tweak (e.g. a new color) only
# needs one edit. Defining all five variables is safe even for scripts that only
# ever reference a subset of them — an unused shell variable has no effect.
if [ -t 1 ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'
else
  G=; R=; Y=; B=; Z=
fi

# Shared ok()/bad() drift-check printers — sourced, not executed. Duplicated
# identically across ~19 scripts (after auto/scripts-drift-var-rename made
# every bad()-with-a-side-effect script use the same `drift` variable) before
# this extraction, found in the same duplication sweep as scripts/lib/yq.sh
# (issue #957). bad() sets the SOURCING SCRIPT's own `drift` variable (plain
# global assignment, not `local` — that's what makes this safe to share: each
# caller still declares its own `drift=0` before running checks and reads
# `$drift` itself at the end, this just supplies the two printer functions).
# Scripts whose bad() has no side effect (they track failure via their own
# separately-managed `fail` variable instead — argocd-crd-ssa-check.sh,
# helm-chart-pin-check.sh, lab-health-check.sh, mimir-readonly-root-check.sh,
# rollouts-plugin-list-check.sh) deliberately keep their own local, no-side-effect
# copy rather than sourcing this one — forcing them onto a drift-setting bad()
# would add an incidental unused `drift` variable to their scope, a behavior
# wrinkle this extraction avoids by design (see scripts/ok-bad-lib-check.sh).
ok()  { printf '  %s✓%s %s\n' "$G" "$Z" "$1"; }
bad() { printf '  %s✗%s %s\n' "$R" "$Z" "$1"; drift=1; }
