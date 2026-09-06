# `scripts/ensure-manifest-tools-hook.sh` — auto-install `kustomize`/`terraform`/`tflint`/`kubeconform` so `make ci`'s validate gates can't self-skip either

CLAUDE.md's bugfix-recurrence-prevention rule; third JANITOR-fallback follow-up
this same run to `auto/ensure-bats-hook` (#1448) and `auto/ensure-lint-tools-hook`
(#1456) — same footgun class, the remaining validate-*.sh tool dependencies.
Verified live none of `kustomize`/`terraform`/`tflint`/`kubeconform` was installed
either, meaning `make ci`'s kustomize/terraform/manifests steps had all been
silently self-skipping the whole run too.

## What was done

Added `scripts/ensure-manifest-tools-hook.sh`, pinning each tool's version to
exactly match `.github/workflows/ci.yml`'s own pins:

- `kustomize` v5.8.1 (GitHub release binary)
- `kubeconform` v0.8.0 (GitHub release binary)
- `terraform` 1.15.9 (releases.hashicorp.com binary)
- `tflint` (via CI's own install script, `terraform-linters/tflint`'s
  `install_linux.sh`)

so a local pass means the same thing a CI pass means, not just "some version
happened to work."

`helm` is deliberately excluded, and the script says why: its official binaries
are hosted exclusively on `get.helm.sh` (verified directly — even its GitHub
release pages link out to `get.helm.sh`, not a GitHub-hosted release asset),
and that host is blocked by this sandbox's egress proxy (organization policy) —
confirmed live by running the official `get-helm-3` install script, which
failed with `connect_rejected`. This only costs
`scripts/helm-chart-pin-check.sh`'s local run (that gate's own soft-skip
message already says so) since `scripts/validate-kustomize.sh` no longer needs
`helm` at all as of 2026-09-06 (ADR-0040's Envoy Gateway removal deleted the
only kustomization that vendored a Helm chart via the `helmCharts` inflator).

## Verification

Ran the freshly-enabled `kustomize`/`terraform`/`manifests` `make ci` steps
after installing all four tools: **zero pre-existing failures** across all
three — `kustomize build` succeeded on every `kustomization.yaml` in
`gitops/`, `kubeconform` schema-validated every manifest cleanly, and
`terraform fmt`/`validate`/`tflint` all passed on `infra/`. The GitHub Actions
backstop had genuinely been keeping all three clean; enabling them locally
didn't surface hidden drift needing a separate fix.

Added `tests/hook-scripts-ensure-manifest-tools.bats` (its own file per
`tests/hook-scripts-coverage.bats`'s frozen-monolith rule) covering:

- the script exists and is executable;
- it reports "already installed" for all four tools when present (the actual
  path this very bats run itself exercises);
- it never fails even with no network/tools reachable — a minimal `PATH`
  exercising only the hook's own non-network coreutils calls (`bash`,
  `timeout`, `mktemp`, `rm`), so every `curl`/`tar`/`install`/`unzip` call
  fails fast with "command not found" and the script still exits 0;
- it explicitly documents the `helm` exclusion and why;
- it is actually wired into `.claude/settings.json`, and that file is still
  valid JSON after the edit.

Deliberately did NOT re-exercise the actual network install paths inside the
bats suite — that would make the suite flaky/slow and duplicate what `make
ci`'s own kustomize/terraform/manifests steps already prove once the tools are
present.

## Why this is in scope for a JANITOR cycle

Third and (for now) final follow-up in this run's mechanical-guard chain:
having found and fixed the identical "a required `make ci` tool is silently
missing in this remote sandbox" bug for `bats` and then `shellcheck`/
`yamllint`, checking every other `validate-*.sh` script's own tool dependency
for the same shape was the natural completion of that sweep, not a new,
unrelated investigation.

## Result

`make ci` passes green (2712+ bats assertions, including the 6 new
`tests/hook-scripts-ensure-manifest-tools.bats` assertions, 0 failures).
`.claude/settings.json` remains valid JSON. No `gitops/` change — this is
tooling/session-config only.

## PR

https://github.com/tooming/k8s-anywhere/pull/1458
