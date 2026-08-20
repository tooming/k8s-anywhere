# Fix stale GitLab reference in docs/dependency-concentration.md

(CHARTER **Core Values** §"Everything as code" + ADR-0004 (no fabricated content);
executor-fallback doc-staleness sweep 2026-08-20, fourth pass this run — reached via
`executor.prompt.md` STEP 6b after three earlier passes this run (kube-state-metrics
chart bump PR #1290; Harbor/Kiali register sweep PR #1291; docs/DR.md Forgejo caveat
PR #1292, all merged) still left the "Now / next" lane fully gated (re-checked: issues
#633/#1229 both re-read, no new comments). **No prerequisites — executor may pick up
immediately.**

`docs/dependency-concentration.md`'s own "Keeping this in sync" section names itself a
downstream consumer of `docs/dependency-register.md`'s table, explicitly warning that
"a future register edit that adds, removes, or renames a row ... should prompt a look
here too — no mechanical drift guard connects the two files." The register's GitLab row
was replaced by a Forgejo row on 2026-08-17 (PR #1205's live cutover, ADR-0035
supersedes ADR-0033) — but this file's "Every other row is a distinct org" list (the
one place every non-grouped register row gets named) still listed **"GitLab (not
GitHub-hosted — gitlab.com/gitlab-org)"**, a row that no longer exists in the register
at all.

Verified directly (ADR-0004): `docs/dependency-register.md`'s current Forgejo row cites
`codeberg.org/forgejo/forgejo, code.forgejo.org/forgejo/runner` as its "Upstream
source" — two different git-forge instances (Codeberg's public instance and Forgejo's
own), both under the `forgejo` org/project name, neither GitHub-hosted (same
not-GitHub-hosted footnote shape this file already uses for Oracle Cloud
Infrastructure and k3s). Replaced the stale GitLab list entry with the equivalent
Forgejo one, reusing the register's own "Upstream source" column text verbatim (this
file's own stated method: "reusing the register's own 'Upstream source' column
verbatim, nothing re-derived from memory").

Also re-verified the file's "32 tool rows" claim (used in the "## Method" section)
against the live register table: still exactly 32 data rows (34 total table lines
minus the header and separator rows) — the GitLab→Forgejo swap was 1-for-1, no count
drift.

No `gitops/` manifest change; `make markdown-links-check` confirmed green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1293
