# GitHub→Forgejo pull-based, fast-forward-only sync workflow

RFC #1340 — architect decision 2026-08-25, groomed 2026-08-25 by the
planner-fallback role. **Decision (RFC #1340, binding):** add a scheduled
Forgejo Actions workflow, `.forgejo/workflows/sync-from-github.yml`
(`on: schedule`, `cron: '*/30 * * * *'`), on the same `runs-on: docker`
runner `.forgejo/workflows/build-sign-push.yml` already uses. It must:
1. Fetch `https://github.com/tooming/k8s-anywhere.git` `main` over plain
   HTTPS (public repo, read-only — no credential needed for the fetch).
2. Attempt `git merge --ff-only` of Forgejo's local `main` onto GitHub's
   `main` tip. Fast-forward-only is the load-bearing choice — it only
   succeeds in the normal case (no divergence) and can never auto-resolve a
   real conflict.
3. On success: push the fast-forwarded `main` to Forgejo's own remote using
   an admin-scoped Forgejo Actions secret token, mirroring
   `build-sign-push.yml`'s own `CHECKOUT_TOKEN` prerequisite-secret pattern.
4. On failure (`--ff-only` rejects — real divergence): fail loudly. Must NOT
   attempt any auto-merge, auto-resolve, or force-push.

Also required: a CLAUDE.md amendment (live-cluster/interactive-session
guidance) requiring any session that commits directly against the live
Forgejo remote to also open a matching GitHub PR with the same fix in the
same session — targets RFC #1340's finding that 38 commits existed on
Forgejo's `main` with no GitHub PR trail at all.

**Explicitly no new/superseding ADR** — additive automation within
ADR-0035's existing scope (Forgejo remains what ArgoCD tracks in-cluster).

## Correction found live during implementation (ADR-0004)

RFC #1340's original text also specified a NetworkPolicy egress rule for the
Forgejo Actions runner (permitting egress to `github.com`/
`codeload.github.com` on 443, mirroring `allow-trivy-egress-vdb.yaml`'s
shape). Before implementing, verified directly (not assumed) against
`forgejo/docker-compose.yml`'s own header comment ("Runs OUTSIDE the
cluster, same architectural tier as GitLab was") and
`scripts/forgejo-runner-ensure.sh` (registers and runs the runner via plain
`docker run --network forgejo_default`, executing job containers over that
Docker network): the Forgejo Actions runner executes entirely **outside**
the Kubernetes cluster, the same tier GitLab previously occupied. ADR-0016's
Cilium default-deny NetworkPolicy governs in-cluster pod traffic only and
has no jurisdiction over this docker-compose tier — a NetworkPolicy
manifest for this component would have been dead configuration, matching
nothing, contrary to ADR-0004's "never fabricate content presented as real
state" principle applied to infrastructure config. **Dropped from the
deliverables; not implemented.** Full reasoning recorded in
`.forgejo/workflows/sync-from-github.yml`'s own header comment so a future
session doesn't reintroduce it without re-checking this fact first.

## What shipped

- `.forgejo/workflows/sync-from-github.yml` — the sync workflow, per the
  Decision above, plus the NetworkPolicy correction.
- `tests/forgejo-sync-workflow.bats` — 12 structural assertions (schedule
  trigger, `--ff-only` present, no `--force`/`-f` anywhere, `CHECKOUT_TOKEN`
  reference with no plaintext credential, `retry_cmd` sourced, pushes to
  Forgejo not GitHub, no rejected git-host name, no `NetworkPolicy` `kind:`
  declaration).
- `docs/DR.md` — a new "Recovery cookbook" entry explaining the two distinct
  failure modes (real divergence vs. network/reachability) and what each
  needs.
- `CLAUDE.md` — new section "Live-cluster/interactive sessions: mirror a
  direct Forgejo fix back to GitHub", the working-agreement rule RFC #1340
  called for.

## ADR-0004 caveats (this remote clusterless session cannot verify)

1. **Whether the scheduled job actually executes and successfully syncs
   against the live Forgejo instance.** No live Forgejo/forgejo-runner
   instance was reachable from this session. A live-cluster session must
   confirm at least one real run.
2. **GitHub reachability from job containers is a known, specifically
   documented risk, not just a generic caveat.** `build-sign-push.yml`'s own
   header comment records a prior live-cluster finding: `data.forgejo.org`
   *and* `github.com` both timed out consistently from inside a job
   container in an earlier session, while the same hosts were reachable in
   under 150ms from the Mac host directly (the same class of Colima-VM
   egress flakiness documented elsewhere in this repo). This job wraps its
   GitHub fetch/push in the same `retry_cmd` budget the rest of this repo's
   CI already relies on for that flakiness class, but if `github.com` proves
   durably unreachable (not just flaky) from job containers, this job's
   whole approach needs a live-cluster session to re-diagnose — e.g. a
   registry-mirror-style workaround, mirroring the `mirror.gcr.io` fix
   already applied for `docker.io` — not a blind retry-budget increase.
   Flagged explicitly in both the workflow file's own header comment and
   `docs/DR.md`'s new recovery-cookbook entry so a live-cluster session
   knows exactly what to check first if this job is failing.

## Out of scope (per RFC #1340)

The one-time reconciliation of the current (as of issue #1335's filing)
118-vs-38 commit divergence between GitHub and Forgejo — needs a
live-cluster session with real Forgejo network access. Tracked separately in
standing `[Action required]` issue #1345.

## PR

auto/forgejo-github-sync-workflow
