# [Action needed] Now/next still gated; dead-code/orphan-script sweep clean

## What's blocked

Same 3 Now/next items, still gated on [#631](https://github.com/tooming/k8s-anywhere/issues/631)
and [#633](https://github.com/tooming/k8s-anywhere/issues/633) — re-checked,
unchanged. Fresh `list_issues`/`list_pull_requests` calls confirm no new
intake and 0 open PRs.

## This run's real output so far

Nine PRs landed this session (#1041–#1049): two real currency/CVE fixes
(Loki, Grafana image tag), a Tempo ADR log-drift correction, an
industry-digest refresh, two dependency-doc staleness fixes, and three
honest `[Action needed]` records.

## This cycle's fresh angle

Cross-checked every `scripts/*.sh` against every invocation surface in the
repo (`Makefile`, `.github/workflows/`, `.claude/settings.json` PostToolUse
hooks, `.githooks/`, and other scripts) looking for orphaned/dead scripts.
Two scripts (`check-merged-pr-push.sh`, `has-open-pr-branches.sh`) initially
looked unreferenced by a narrow grep (extension-filtered, missing
`.githooks/pre-push`/`.githooks/post-merge` which have no file extension)
— broadened the search and confirmed both are real, wired-in call sites, not
dead code. All `*-hook.sh` scripts are wired into `.claude/settings.json`'s
PostToolUse hooks (30 references confirmed), not the Makefile — the two are
intentionally separate invocation mechanisms, not a gap. No dead code found.

## Assessment

No new buildable Now/next work found this cycle.

## What would unblock further work

(a) a maintainer-confirmation comment on #631 or #633; (b) a new GitHub
issue (intake); (c) a new upstream release/CVE firing a tracked flip
condition.

Per `executor.prompt.md` STEP 8 this is not a stopping point — the run
continues to the next cycle.
