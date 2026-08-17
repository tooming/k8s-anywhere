# Update `docs/dependency-register.md`'s GitLab row to a Forgejo row

(ADR-0035 item 7; DOC-DRIFT-AUTHOR-fallback pass 2026-08-17, sixth cycle this run,
reached via `executor.prompt.md` STEP 6b after the topmost Now/next item — the
GitLab→Forgejo script/Makefile rename — was investigated and correctly deferred
with findings this same run (`auto/forgejo-rename-item-investigation-note`, PR
#1208) rather than risking a broken `make up`; the item below it is sequentially
blocked on that one, and every other Now/next item remains gated on #631/#633. **No
prerequisites — executor may pick up immediately.**

Explicitly flagged as outstanding follow-up by two independent sources this run: PR
#1205's own body ("`docs/dependency-register.md`'s GitLab row still needs updating
to reflect Forgejo as the live component") and this run's
`docs/industry/2026-W34-digest.md` ("For the architect" section, same finding).
ADR-0035's own migration-execution list (item 7) already named this exact edit as
"a one-line, low-risk edit unlike the rest of the migration" — low risk because
it's pure documentation reflecting an already-verified, already-merged reality (PR
#1205's live cutover), not a new live-infra action.

Updated the register's scope note (explaining why GitLab wasn't previously excluded
like Redis/Artifactory — now corrected: GitLab stopped being the live component
2026-08-17, so it now follows that same pattern one step early, ahead of the still-
pending decommission item) and the table row itself: renamed `GitLab` → `Forgejo`,
citing ADR-0035 (supersedes ADR-0033) as primary, with GitLab's
stopped-but-rollback-kept state noted inline. Corrected the adjacent "24 have a
row, ADR-0035 is the transitional exception" sentence to "all 25 now have a row" —
ADR-0035 gained its row in this same edit.

**Self-caught during drafting:** an early draft of the Forgejo row's "Last
reviewed" cell cited `docs/industry/2026-W34-digest.md` for independently
reconfirming the `forgejo:16.0.2`/`runner:13.0.0` image pins — checked the digest
file directly and found it does **not** contain that claim (it only discusses the
GitLab→Forgejo cutover event, not image-tag currency). Corrected the citation to
this run's own earlier direct currency check instead of a file that doesn't
actually support the claim (ADR-0004 — never cite a source that doesn't say what
you're claiming it says).

**ADR-0004 caveat:** this remote clusterless session cannot independently
re-verify PR #1205's live cutover claims beyond reading its merged diff/body — the
row's content traces to that PR's own text (repoURL flip counts, GitLab
stop/rollback state), not a fresh live check against the actual cluster.

## PR

(filled in after PR creation)
