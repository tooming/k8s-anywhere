# Fix `verify-rejection`'s unclosable heredoc in `build-sign-push.yml`

CHARTER **Core Values** §"Everything as code" + CLAUDE.md's "every bugfix must prevent
recurrence" — found live during an executor self-review pass, 12th cycle this run,
while adversarially re-reviewing this run's own earlier work (the `verify-rejection`
job, PR #1224, merged earlier this run) after PLANNER/ARCHITECT/UPGRADE-DRAFTER/
DOC-DRIFT-AUTHOR/TRIAGER/JANITOR's usual fallback-chain checks all found nothing
further this cycle (Now/next lane still fully gated).

## What was found

The "Assert Kyverno rejects the unsigned image at admission" step fed a test Pod
manifest to `kubectl apply -f -` via `cat <<'PODYAML' | kubectl apply -f - ... PODYAML`.
The closing `PODYAML` delimiter sat at the same indentation as every other line inside
the step's YAML `run: |` block-literal scalar (confirmed via `grep -n "PODYAML" ... |
cat -A`: 10 leading spaces, not column 0).

Because the heredoc used a *quoted* opening tag (`<<'PODYAML'`, no `-` modifier), bash
requires the closing delimiter to match at column zero exactly — no leading whitespace
tolerated. But a YAML block-literal scalar (`run: |`) can't have a less-indented line
without ending the scalar early, per YAML's own indentation rules. There was no way to
de-indent just the terminator line without breaking the YAML structure instead of the
heredoc. Net effect: the heredoc could never actually close — this step would have
broken the entire job the first time it ran, since the shell would keep reading
subsequent YAML as heredoc body forever (or until EOF/parse failure).

Root cause: this is a structural incompatibility between quoted multi-line heredocs and
indented YAML block-literal scalars, not a typo — it can't be fixed by adjusting
indentation in place. Never exercised live: no Forgejo Actions run has executed this job
yet (ADR-0004, same caveat already recorded in PR #1224's own body), so this was caught
only by re-reading the step's own YAML structurally, not by a failed run.

## Fix

Replaced the heredoc with a single-line JSON payload (`echo '{...}' | kubectl apply -f
-`) — YAML is a JSON superset and `kubectl apply -f -` accepts JSON directly, so no
multi-line shell construct is needed inside the indented `run:` block at all. Formatted
the JSON with a space after each colon for readability; behavior is identical either
way.

Updated the two `tests/forgejo-ci.bats` assertions that had asserted the step's
security-context/imagePullSecret fields via YAML-style `key: value` substrings (`grep`
patterns like `"runAsNonRoot: true"`) — those never match JSON's `"key": value` form
(JSON always quotes keys), so the assertions were rewritten to match the JSON
equivalents (`'"runAsNonRoot": true'`, `'"drop": ["ALL"]'`, etc.), preserving exactly
the same underlying property being checked (the test Pod's securityContext/
imagePullSecret still matches `gitops/apps/capstone/rollout.yaml`'s own values).

**Mechanical guard** (CLAUDE.md's "every bugfix must prevent recurrence"): added
`tests/forgejo-ci.bats` assertion `"verify-rejection's test Pod is applied via a
single-line JSON payload, not a heredoc"`, scoped to the step's own body (between its
`name:` line and the next step's `name:` line) and asserting no quoted-heredoc opening
tag (`<<'`) appears there — a future edit reintroducing a multi-line heredoc into this
indented `run:` block fails this test immediately.

## Verification

This remote clusterless session cannot execute a live Forgejo Actions run to observe
the original failure or the fix empirically (ADR-0004, same caveat as every CI-workflow
change in this repo) — the finding is a structural read of bash heredoc-matching rules
against YAML block-literal-scalar indentation rules, not a reproduced live failure.
`python3 -c "import yaml; yaml.safe_load(...)"` confirms the file is still valid YAML.
`make ci` passes: full local suite green (bats/shellcheck already installed this
session), including the rewritten and new `tests/forgejo-ci.bats` assertions (26/26).

## PR

(filled in after PR creation)
