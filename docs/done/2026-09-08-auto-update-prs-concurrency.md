# Add a concurrency group to auto-update-prs.yml

Found live 2026-09-08 (cycle 25 of this autonomous run — continuing cycle
24's CI-workflow-safety lens onto the remaining `push: [main]`-triggered
workflow). `.github/workflows/auto-update-prs.yml` fires on every push to
`main` and rebases every open PR branch onto the new tip via
`git cherry-pick` + `git push --force-with-lease`. This repo's own
self-merge routines push to `main` in rapid succession — a squash-merge is
itself a push event, and this run alone landed 5 in the last hour
(#1533–#1537) — so two runs of this workflow overlapping is not a
hypothetical, it is the routine case, same root observation that
motivated `ci.yml`'s own concurrency group (cycle 19 of this run).

Unlike `ci.yml`'s change, this one is not preventing wasted compute on an
otherwise-harmless duplicate run — `--force-with-lease` already makes a
stale run's push attempt fail safely (lease mismatch) rather than
clobbering a newer run's work — but a stale run's failed push still logs a
scary-looking, confusing failure in the Actions history for no real
reason once a newer run (which re-fetches and re-rebases against the
actual latest `main`) has already superseded it.

## What was done

Added a `concurrency` block keyed by `github.ref` (this workflow only ever
triggers on `push: [main]`, so the ref is always the same value — no need
for a PR-number-style key). `cancel-in-progress: true`, safe specifically
because of `--force-with-lease`: cancelling a superseded run mid-flight
leaves whatever it already successfully force-pushed as-is (each PR
branch's rebase-and-push is a fully independent unit within the run's
loop), and the newer run repeats the entire sweep against the latest
`main` regardless, so nothing is lost by cutting a stale run short.

## Validation

`yamllint -c .yamllint.yml` and `yq eval '.'` both clean on the edited
file. `make ci` — full local run, exit code 0, zero `not ok` lines (bats +
kustomize + terraform + drift checks all green, including
`workflow-timeout-check.sh`, unaffected since `timeout-minutes` didn't
move). Cannot integration-test actual overlapping-push behavior from this
clusterless session (would require two real near-simultaneous pushes to
`main` and inspecting the live Actions run history) — verified by
inspection against GitHub's documented `concurrency:` semantics and this
workflow's own `--force-with-lease` safety property instead.

## PR

[#1538](https://github.com/tooming/k8s-anywhere/pull/1538) (autonomous
scheduled executor run, cycle 25 — continuing cycle 24's CI-workflow-safety
lens).
