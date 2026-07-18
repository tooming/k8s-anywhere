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
