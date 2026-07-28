# [Action needed] Now/next still gated; Terragrunt variable-consistency sweep clean

## What happened this cycle

ROADMAP.md's *Now / next* lane remains fully gated on the standing maintainer-confirmation
issues [#631](https://github.com/tooming/k8s-anywhere/issues/631),
[#632](https://github.com/tooming/k8s-anywhere/issues/632),
[#633](https://github.com/tooming/k8s-anywhere/issues/633) (re-verified: all three still
open, zero comments). This run has now shipped twelve real, merged deliverables (PRs
#789, #790, #792–#801), including two live-cluster bugfixes (#796, #797).

Two lenses this cycle, both clean:

1. **`.gitlab-ci.yml` re-audit.** Reviewed the capstone build/sign pipeline fresh. Its own
   inline comment already documents and correctly reasons through the one thing that looks
   at first glance like a bug (only the `$CI_COMMIT_SHORT_SHA` tag is cosign-signed, not
   `:latest`) — confirmed this was already investigated once before (PR #497,
   referenced from issue #498's body: "turned out not to be a bug"), and the reasoning
   (cosign signs by content digest, `docker tag` makes `:latest` an alias of the same
   digest, so one signature covers both) is sound. No new finding.
2. **Terragrunt input-vs-module-variable consistency.** For all three `infra/live/local/*`
   units (`argocd`, `cluster`, `gitlab`), precisely extracted every key set inside each
   `terragrunt.hcl`'s `inputs = { ... }` block and diffed it against the corresponding
   module's declared `variable` blocks. `argocd` (1 input) and `cluster` (7 inputs) match
   exactly — every set input is a real declared variable, nothing set is undeclared.
   `gitlab` sets no `inputs` block at all — intentional, relying entirely on the module's
   variable defaults (`argocd_namespace`, `group_path`, `project_name`,
   `repo_url_in_cluster`) — not an omission.

No actionable gap surfaced from either lens this cycle.

## What this is

The self-merging `[Action needed]` PR breadcrumb pattern (never the word "idle") — this
cycle's honest record per CLAUDE.md's "every run ships a PR" rule. Not a stopping point;
the run continues to the next cycle.
