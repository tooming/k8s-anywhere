# `scripts/ensure-yq-hook.sh` — auto-install `mikefarah/yq` so `make ci`'s yq-only gates can't self-skip either

CLAUDE.md's bugfix-recurrence-prevention rule; fourth JANITOR-fallback follow-up
this same run to `auto/ensure-bats-hook` (#1448), `auto/ensure-lint-tools-hook`
(#1456), and `auto/ensure-manifest-tools-hook` (#1460) — same footgun class, this
time `scripts/lib/yq-variant.sh`'s `require_mikefarah_yq()`, which deliberately
soft-skips (exit 0, `CI` unset) any mikefarah-yq-only gate when the `yq` on `PATH`
isn't that variant — a fair convenience for a human contributor without it
installed, but an autonomous executor session's *entire* self-review is `make ci`
(per `routines/executor.prompt.md`, WAYS-OF-WORKING.md §0.1's self-merge model):
there is no separate human reviewer to catch what a locally green-but-actually-
skipped `make ci` missed.

## How this was found

Found live while validating PR #1461 (the Traefik web/tls IngressRoute split):
this sandbox's apt-installed `/usr/bin/yq` is the Python/jq-wrapper variant
(`yq 0.0.0`, no "mikefarah" in its version string), not mikefarah/yq. That meant
`tests/ingressroute-web-tls-check.bats`'s own "fails when one object combines web +
tls" assertion silently soft-skipped locally instead of actually detecting the
violation — even though the identical commit's real GitHub Actions run reported
`unit: success`. Confirmed by reading `.github/workflows/ci.yml`'s own "Install yq
+ helm" step, which already installs this exact mikefarah/yq binary to this exact
path — so main was never actually broken; this is a local-sandbox validation gap
only, not a bug on main.

## What was done

Added `scripts/ensure-yq-hook.sh`, a best-effort `SessionStart` hook using the
identical install command `.github/workflows/ci.yml`'s own "Install yq + helm"
step uses (minus `sudo`, since this session already runs as root) to install
mikefarah/yq to `/usr/local/bin/yq` — which precedes `/usr/bin` on `PATH` — so a
local pass means the same thing a CI pass means, not just "some `yq` happened to
be present."

Never blocks or fails the session: if the yq already on `PATH` is mikefarah's
variant, it no-ops with a confirming message; if the download fails (no network,
egress-proxy block, GitHub releases unreachable), it silently no-ops with an
explanatory message rather than erroring out, exactly like its three sibling
hooks (`ensure-bats-hook.sh`, `ensure-lint-tools-hook.sh`,
`ensure-manifest-tools-hook.sh`).

## Verification

Verified live both code paths:

- **Already-installed branch**: with mikefarah/yq already on `PATH`, the hook
  detects it via `yq --version 2>&1 | grep -qi mikefarah` and exits 0 immediately
  with no network call.
- **Fresh-install branch**: with a minimal `PATH` (no `yq`), the hook downloads
  the binary, `chmod +x`s it, and re-verifies via the same `mikefarah` version
  check before reporting success.

Re-ran `tests/ingressroute-web-tls-check.bats` after installing mikefarah/yq: all
4 assertions passed for real (previously the violation-detection assertion had
been silently soft-skipping).

Added `tests/hook-scripts-ensure-yq.bats` (its own file per
`tests/hook-scripts-coverage.bats`'s frozen-monolith rule) covering:

- the script exists and is executable;
- it reports "already installed" when mikefarah/yq is present on `PATH` (the
  actual path this very bats run itself exercises);
- it never fails even with no network/yq reachable — a minimal `PATH` exercising
  only the hook's own non-network calls (`bash`, `grep`, `chmod`), so the `curl`
  call fails fast with "command not found" and the script still exits 0;
- it is actually wired into `.claude/settings.json`, and that file is still valid
  JSON after the edit.

Deliberately did NOT re-exercise the actual network install path inside the bats
suite — that would make the suite flaky/slow and duplicate what `make ci`'s own
mikefarah-yq-only steps already prove once the tool is present.

## Why this is in scope for a JANITOR cycle

Fourth and (for now) final follow-up in this run's mechanical-guard chain: having
found and fixed the identical "a required `make ci` tool is silently missing or
wrong-variant in this remote sandbox" bug for `bats`, then `shellcheck`/
`yamllint`, then `kustomize`/`terraform`/`tflint`/`kubeconform`, discovering the
same shape for `yq`'s variant requirement while validating an unrelated PR was the
natural completion of that sweep, not a new, unrelated investigation.

## Result

`make ci` passes green, including the 5 new `tests/hook-scripts-ensure-yq.bats`
assertions, 0 failures. `.claude/settings.json` remains valid JSON. No `gitops/`
change — this is tooling/session-config only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1466
