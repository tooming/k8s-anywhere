# [Action needed] Now/next still gated; fresh-run full fallback-chain sweep clean

## What's blocked

ROADMAP.md's *Now / next* lane holds exactly 3 unchecked `[ ]` items, and all
three are still gated:

1. `verifyImages ClusterPolicy — Audit → Enforce flip` — gated on
   [#631](https://github.com/tooming/k8s-anywhere/issues/631) (confirm a real
   GitLab CI run signed and pushed an image to Harbor).
2. `O4 CI gate — verify-image-rejection job in GitLab CI` — depends on item 1
   merging first.
3. `Remove legacy capstone Deployment` — gated on
   [#633](https://github.com/tooming/k8s-anywhere/issues/633) (confirm an Argo
   Rollouts canary + Kargo promotion has run end-to-end).

Both #631 and #633 are still open and unconfirmed. Per their latest comments
(2026-08-04, ~00:15 UTC), a live interactive maintainer session is actively
working the root blocker for both — no GitLab Runner had ever been registered
against this lab's GitLab instance — and has an open PR
([#980](https://github.com/tooming/k8s-anywhere/pull/980),
`feat/gitlab-runner-and-registry-port-fix`) in flight to fix it. Neither issue
has a confirmation comment yet, so both gated items remain correctly skipped.

## This is a fresh scheduled run — full fallback chain re-walked, nothing stale assumed

This session is a new scheduled firing (not a continuation of the very long
prior run that shipped PRs #969–#986 earlier today). Per `executor.prompt.md`
STEP 1b/STEP 2, re-verified from scratch: `make stale-prs-check` found no `gh`
CLI locally, so I checked every open PR directly via the GitHub MCP tools —
only one is open, human-authored `feat/gitlab-runner-and-registry-port-fix`
(#980, not an agent-prefixed branch, nothing to finish on my end). No
duplicate in-flight `auto/*` work exists for the gated items.

Walked the full STEP 6b fallback chain, each checked freshly this run (not
copied from the earlier session's notes):

1. **PLANNER** — `docs/roadmap/incoming/` holds only its `README.md` (no
   pending architect items). The only open, unlabeled-`groomed` issues are
   #631/#633 themselves — standing confirmation gates, not groomable backlog
   items. Grepped the entire ROADMAP.md for `- [ ] 🟢` / `- [ ] 🟡`: exactly
   the same 3 gated 🟢 items above and **zero** 🟡 items anywhere in the file
   (every 🟡 item that ever existed is either struck through with a `Groomed
   ↗` note or checked `[x]`) — there is genuinely nothing later in the
   backlog to promote into *Now / next*, satisfying the "no green-able work
   to promote" exit condition explicitly.
2. **ARCHITECT** — `gh issue list --label adr-audit --state open` equivalent
   (via `search_issues`) returned zero open audits. Zero un-RFC'd 🟡 items
   (see above) means STEP 3/4 have nothing to act on either. A full weekly
   upstream-release sweep (STEP 2b) is architect's job on its own cadence;
   this fallback pass confirms no *stranded* audit or un-RFC'd item, which is
   the specific gap this chain step exists to catch.
3. **UPGRADE-DRAFTER** — checked 16 chart/component sources directly against
   real upstream release pages this run (not reused from the earlier
   session): `cert-manager` (v1.21.1), `cilium` (v1.18.12), `harbor-helm`
   (v1.19.2), `kro` (v0.9.3), `kargo` (v1.11.0), `tidb-operator` (v1.6.5 —
   only 1.6.x tag; newer lines are `1.7.0-alpha`/`2.x` pre-release or major),
   `envoy-gateway` (v1.8.3), `external-secrets` (v2.8.0), `argo-rollouts`
   chart (`argo-rollouts-2.41.1`), `velero` chart (`velero-12.1.0`),
   `trivy-operator` chart (`trivy-operator-0.34.0`), `longhorn` (v1.11.3),
   `vault-helm` (v0.34.0), `kyverno` chart (`kyverno-chart-3.8.2` — newest
   `3.9.0-rc.1` is a pre-release, correctly skipped), `aws s3-controller`
   (v1.8.2), `keda` chart (v2.20.2). **Every one is already at the highest
   stable release** — no upgrade PR available.
4. **DOC-DRIFT-AUTHOR** — ran `make ci`'s clusterless checks directly
   (`bats`/`kustomize`/`terraform`/`shellcheck`/`yamllint`/`kubeconform`/`helm`
   aren't installed in this sandbox, so those specific jobs skip locally and
   run in GitHub Actions instead — expected, not a failure): `readme-check`,
   `lab-ui-check`, `roadmap-check`, internal markdown links, ADR chart-version
   sync, ADR image-pin sync, `context.md` version sync, orphaned-kustomize
   files, `routines/` apply-sync — all ✓, zero drift signals.
5. **TRIAGER** — the only two open issues (#631, #633) already carry a
   `domain:*` + `readiness:*` + `priority:*` label each. Nothing to triage.
6. **JANITOR** — re-ran the scripts/ function-duplication sweep
   (`grep -hoE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)\s*\{' scripts/*.sh scripts/lib/*.sh`)
   fresh this run: identical result set to the prior session's exhaustive
   pass (`g()`, `ok()`/`bad()`, `fail()`, `cleanup()` — all already
   individually dispositioned as not genuine duplication or too thin to
   justify a PR). Tried a fresh angle not used earlier today: `gitops/`
   manifest duplication — every `kustomization.yaml` in the repo (`find
   gitops -name kustomization.yaml | xargs md5sum`) hashes to a **unique**
   value; no byte-identical manifest pair exists to template out. No
   janitor-sized cleanup survived scrutiny.

## Assessment

Every rung of the fallback ladder came up genuinely empty on a freshly-run
check this cycle, not an assumption carried over from the earlier session.
The backlog, dependency currency, doc sync, issue triage, and script/manifest
duplication are all clean as of this run.

## What would unblock further work

Unchanged from earlier today: (a) a maintainer-confirmation comment on #631
or #633 (PR #980 is the live in-progress work toward that); (b) a new GitHub
issue (ungroomed intake); (c) a new upstream CVE/release firing a tracked ADR
flip condition; (d) a future run trying a lens not yet exercised (e.g. a
Terraform-module-level duplication sweep, or a fresh CHARTER Objective
deep-dive against O2/O3/O5's own bats coverage rather than presence checks).

This note is this cycle's honest record. Per `executor.prompt.md` STEP 8 this
is not a stopping point — the run continues to the next cycle.
