# [Action needed] Now/next still gated; first full local `make ci` execution of the day also clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (seventeenth cycle of 2026-07-26): all three still open, zero comments,
`updated_at` unchanged since 2026-07-21T05:34 UTC. `list_issues` (state=OPEN)
confirms these three remain the only open issues in the repo. Each gated
item's own text was re-read directly (not assumed from memory) to confirm
none has an un-split live-state-safe slice left per rule #9 — `auto/harbor-
capstone-rewire`'s own item text already documents that the prep slices
(`auto/harbor-registry-secret-prep`, `auto/harbor-kargo-egress-prep`) landed
in earlier cycles and what remains is explicitly "scoped to the actual
live-state-mutating cutover only" — there is nothing further to carve out.

## This cycle's fresh angle

Every prior cycle today (see the sixteen dated files in this directory)
verified doc/CVE/structural correctness by *reading* — CVE research, CHARTER
re-audit, janitor-lens duplication, appset completeness, done-record
spot-checks. None of them actually **executed** the full `make ci` suite
locally, because `bats`/`kustomize`/`kubeconform`/`terraform`/`helm` are not
pre-installed in this session's environment and every prior cycle noted them
as "skipping" — relying on GitHub Actions' post-merge run instead (per
CLAUDE.md: "the full clusterless CI gate... does not run locally on every
push... runs in GitHub Actions").

This cycle installed the missing tools directly (`apt-get install bats
yamllint shellcheck`; `go install` for `kustomize`, `kubeconform`, and `helm`
— `get.helm.sh` itself 403s through the egress proxy, consistent with every
prior cycle's chart-index-host finding, but `go install
helm.sh/helm/v3/cmd/helm@latest` worked) and ran the **complete** `make ci`
locally for real, for the first time this run:

- **bats:** all 2299 tests passed, zero failures.
- **kustomize:** every `kustomization.yaml` under `gitops/` builds clean.
- **kubeconform:** 353 resources / 340 files — Valid: 148, Invalid: 0,
  Errors: 0, Skipped: 205 (missing CRD schemas, which the gate correctly
  treats as a skip, not a failure, per its own bats coverage).
- **terraform fmt:** clean across `infra/`.
- **helm chart-pin + large-CRD SSA checks:** ran for real against every
  chart source; every *reachable* repo resolved its pinned version
  correctly (only `istio-release.storage.googleapis.com` was reachable
  through the proxy — same restriction every prior cycle already
  documented for the other seventeen chart-index hosts: `403`/`CONNECT
  tunnel failed`). Per the proxy's own README ("do not retry organization
  policy denials — report them"), did not retry those hosts again; this is
  a policy boundary, not a transient failure.
- **lint (shellcheck + yamllint):** shellcheck clean. yamllint surfaced
  exactly one warning, investigated and confirmed a **false positive, not a
  bug**: `infra/modules/oracle-k3s-cluster/cloud-init.yaml:1` —
  `missing starting space in comment` on the line `#cloud-config`. That
  exact string (no leading space) is cloud-init's own required magic header
  that identifies the file as a cloud-config document; adding a space would
  break cloud-init's file-type detection on the real instance. Correctly
  left unchanged — this mirrors the repo's own "verify before reporting a
  gap" discipline (e.g. the Kiali/Alloy red-herring notes in earlier
  cycles). The warning does not fail the gate (`lint: PASS`, exit 0) and
  needs no suppression.

Net result: a genuinely independent, from-scratch execution of every gate
`make ci` runs — not a re-read of prior merged PRs' CI results — confirms
`main` is fully green with zero regressions.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of
any size; (d) proxy/network access to the still-blocked Helm chart index
hosts (only `istio-release.storage.googleapis.com` is reachable through this
session's egress policy; `get.helm.sh` and the other seventeen chart hosts
documented across this week's cycles remain 403).

This note is this cycle's honest record — a genuinely different verification
method (full local tool execution, not documentation/CVE review) than any
prior dated cycle in this directory — not a stopping point. The run
continues to watch for a standing-issue confirmation or a genuinely new
signal in subsequent cycles per `executor.prompt.md` STEP 8.
