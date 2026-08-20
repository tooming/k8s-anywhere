# docs/platform-products.md: cross-reference the GitLab-vs-Forgejo bootstrap gap

(CHARTER **Core Values** §"Everything as code" + ADR-0004 (no fabricated content);
executor-fallback doc-staleness sweep 2026-08-20, fifth pass this run — reached via
`executor.prompt.md` STEP 6b after four earlier passes this run (kube-state-metrics
chart bump PR #1290; Harbor/Kiali register sweep PR #1291; docs/DR.md Forgejo caveat
PR #1292; dependency-concentration.md GitLab→Forgejo fix PR #1293, all merged) still
left the "Now / next" lane fully gated (re-checked: issues #633/#1229 both re-read, no
new comments). **No prerequisites — executor may pick up immediately.**

Three earlier cycles this run (PR #1289 for README.md/docs/00-architecture.md, PR
#1292 for docs/DR.md) added a "GitLab vs. Forgejo, as of 2026-08-17" caveat to docs
that describe `make up`'s literal bootstrap sequence — a fresh bootstrap still
provisions GitLab (ADR-0033/ADR-0035, unchanged), but the currently-running lab's
ArgoCD was separately re-pointed at Forgejo directly on the live cluster (PR #1205)
without `make up`'s script being updated to match. This cycle found the same
un-caveated gap in a fourth doc: `docs/platform-products.md`'s "Layered dependency
tree" section — a Mermaid diagram (`scm["Source of truth: GitLab"]`) plus its
accompanying Tier-0 table row, both naming GitLab as "today's" SCM without mentioning
the live cutover.

`docs/platform-products.md` explicitly names itself "the org/product companion to
[dependency-tree.md]... and [00-architecture.md]" — the exact two docs whose own
GitLab/Forgejo caveats this cycle's fix now cross-references, closing the gap on the
one companion doc in that trio that hadn't received it yet.

Added the same caveat blockquote shape used in the prior three fixes, placed right
before the Mermaid diagram (the first GitLab mention in the file) — one caveat near
the top rather than repeating it at each of the file's other two GitLab mentions
further down (a "Continuous Delivery" capability row, a summary table), matching how
the README.md fix placed a single caveat near its own first GitLab table row rather
than annotating every later mention.

No `gitops/` manifest change; `make markdown-links-check` confirmed green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1294
