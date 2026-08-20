# docs/DR.md: cross-reference the GitLab-vs-Forgejo bootstrap gap

(CHARTER **Core Values** §"Everything as code" + ADR-0004 (no fabricated content);
executor-fallback doc-staleness sweep 2026-08-20, third pass this run — reached via
`executor.prompt.md` STEP 6b after the first two passes' kube-state-metrics chart bump
(`auto/ksm-chart-8-4-0`, PR #1290, merged) and Harbor/Kiali register sweep
(`auto/dependency-register-harbor-kiali-currency-sweep`, PR #1291, merged) still left
the "Now / next" lane fully gated (re-checked: issues #633/#1229 both re-read, no new
comments since the prior cycles). **No prerequisites — executor may pick up
immediately.**

An earlier cycle in this same run (`chore/architecture-doc-gitlab-forgejo-caveat`, PR
#1289, merged) added the "GitLab vs. Forgejo, as of 2026-08-17" cross-reference to
README.md and docs/00-architecture.md — both describe `make up`'s bootstrap sequence
and needed the same caveat docs/dependency-tree.md already carried (the live cluster
was cut over to Forgejo directly, PR #1205, without `make up`'s bootstrap script being
updated to match — a deliberately deferred, tracked gap, not a bug).

This cycle found the same gap in a third doc: `docs/DR.md`'s "GitLab (the DR irony)"
section (under "Single points of failure") describes GitLab as the recovery-path SPOF,
and its "The order (what `make up` does, and why)" table's steps 7–8 name
`gitlab-up`/`gitlab-configure` — both accurate to `make up`'s actual, current,
unchanged behavior (verified directly against `Makefile`'s `up:` target, which still
calls `gitlab-up`/`gitlab-configure` in that literal order — ADR-0004). But the section
never mentions that the *currently-running* lab's actual recovery-path SPOF is Forgejo,
not GitLab, since the live cutover — the same gap already closed for README.md and
docs/00-architecture.md, just not yet for this doc.

Added the same shape of caveat blockquote used in README.md/docs/00-architecture.md's
prior fix, adapted to this doc's DR/SPOF framing (the recovery-path-SPOF reasoning
applies identically to either git source, so the note doesn't change any of the DR
guidance below it — it just names which one is actually live today), placed right
after the "### GitLab (the DR irony)" heading and cross-referencing
`docs/dependency-tree.md`'s own "Known gap, not yet reconciled" note (the original
source of this caveat's wording).

No `gitops/` manifest change; `make markdown-links-check` and `make readme-check`
confirmed green.

## PR

(filled in after PR creation)
