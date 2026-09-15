# Rename `scripts/gitlab-*.sh` → `scripts/forgejo-*.sh` + matching `Makefile` targets

> **Note (JANITOR-fallback trim, 2026-09-15):** this item never shipped a rename — it
> was **closed as moot 2026-09-07** when both GitLab and Forgejo were removed from the
> project entirely (no replacement), so there was nothing left to rename. This file is
> the mirror `ROADMAP.md`'s legacy-item-trim lens (batches 1-12, same pattern) requires
> before the inline copy can be condensed to a pointer — this item was explicitly
> skipped by batch 12 ("no clean mirror") because that mirror didn't exist yet. It does
> now; this file *is* that mirror, verbatim from the last full ROADMAP.md copy before
> trimming.

closed as moot 2026-09-07: GitLab was fully decommissioned (the item right below it in
ROADMAP.md — "Decommission `gitlab/docker-compose.yml` + `infra/modules/gitlab-config`"),
then Forgejo itself was also removed entirely, no replacement, the same day (ADR-0035's
Status) — the repo now lives only on its public GitHub remote, so neither a
`gitlab-*.sh`→`forgejo-*.sh` rename nor a `forgejo-*.sh` script of any kind has anything
left to apply to.

(bootstrap, TLS bootstrap, push, force-push, `rebase-prs`' GitLab leg);
`tests/gitlab-compose.bats`/`tests/gitlab-push.bats` → `forgejo-*` bats files with
equivalent coverage (mechanical-guard parity, not a regression). Prerequisite item
(repoURL flip) is now done and GitLab itself is stopped (2026-08-17, `make
gitlab-down`) — these scripts are dead code pointing at a stopped service, so this
is now safe/overdue, not merely unblocked.

Investigated 2026-08-17, re-confirmed still blocked 2026-09-06 — not a mechanical
rename; the push auth model changes shape entirely (GitLab's HTTPS+PAT → Forgejo's
SSH deploy key), Forgejo likely needs no TLS-bootstrap equivalent at all, and
`make up`'s bootstrap sequence still calls the GitLab targets outright, needing a
live-cluster session to design and verify the replacement end-to-end. Two adjacent
gaps this investigation surfaced were closed in the meantime (the missing
`repo-forgejo-gitops` Secret bug; GitLab left running post-bootstrap burning ~3 GiB)
without touching the rename/decommission itself. Full findings, recommendation, and
update history:
[docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md](../roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md).
Left unchecked rather than shipping a same-shaped-but-wrong rename (ADR-0004).

**Update 2026-09-06 (live-cluster session) — the credential-wiring half of "`make
up`'s bootstrap sequence still calls the GitLab targets outright" is now closed**,
independently of this item: a fresh `make up` was reproduced live failing
`root-app`'s very first sync (missing `repo-forgejo-gitops` Secret — the exact gap
this investigation flagged). Fixed with `scripts/forgejo-repo-secret.sh` +
`make forgejo-repo-secret`, wired into `up` right after `forgejo-up` and before
`gitlab-up`/`root-app` — full writeup:
[docs/done/2026-09-06-forgejo-repo-secret-bootstrap-gap.md](2026-09-06-forgejo-repo-secret-bootstrap-gap.md).
This item stays open: the SSH-based `forgejo-push`/`forgejo-force-push` replacement,
the TLS-layer question, and the actual `gitlab-*.sh` → `forgejo-*.sh` rename are
still undone — GitLab's targets still run in `up`, and no automated push exists yet
for a genuinely empty Forgejo repo.

**Update 2026-09-06 (live-cluster session, issue #633) — "legacy, harmless" was
wrong about the resource cost, even though the correctness call was right.**
`docker stats` showed the `gitlab` container alone holding ~3.1 GiB (27% of the
12 GB VM) for the entire rest of a session after a `make up`, because nothing in
the `up` sequence ever brought it back down — `gitlab-configure` only needs GitLab
reachable for its own one-shot Terraform-state import + initial push, and nothing
later in `up` (`root-app` now tracks Forgejo, per the repoURL flip already
mentioned above) depends on it staying up. Added `$(MAKE) gitlab-down` right after
`gitlab-configure` in the `up` target — GitLab still gets configured every fresh
bootstrap, it just doesn't sit there afterward burning a quarter of the VM. This is
a narrow, safe addition, not the full decommission this item is still tracking.

**Update 2026-09-07 — moot: both GitLab and Forgejo removed entirely.** This item's
entire premise (choosing how to rename `gitlab-*.sh` scripts to a `forgejo-*.sh`
equivalent) no longer applies: GitLab was fully decommissioned, then Forgejo itself
was also removed entirely, no replacement, the same day (ADR-0035's Status) — the
repo now lives only on its public GitHub remote. Neither `scripts/gitlab-*.sh` nor
`scripts/forgejo-*.sh` exists in the repo any more, and no `gitlab-*`/`forgejo-*`
`Makefile` targets remain either. Marked `[x]` "closed as moot 2026-09-07" in
`ROADMAP.md`; the standalone investigation file
([docs/roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md](../roadmap/investigations/2026-08-17-gitlab-forgejo-rename.md))
got its own matching closing update the same day, separately.

## PR

#1629
