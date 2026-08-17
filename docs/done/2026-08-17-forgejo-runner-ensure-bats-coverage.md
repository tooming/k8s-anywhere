# `scripts/forgejo-runner-ensure.sh` has no bats coverage at all — its two sibling bootstrap scripts do

(CHARTER **Core Values** §"Everything as code" + ROADMAP rule #9's own named filler example, "a script with no bats coverage"; planner-fallback coverage/hardening sweep 2026-08-17, fourth pass this run, reached via `executor.prompt.md` STEP 6b — every Now/next item is still gated (the three standing GitLab→Forgejo migration items plus the `verifyImages` Enforce flip, the O4 CI-rejection-gate, and the legacy capstone `Deployment` removal, all still gated on unconfirmed maintainer-confirmation issues #631/#633, re-checked this cycle — no new comment since 2026-08-13 05:57 UTC — and this run's first three PLANNER-fallback passes already claimed the gaps their sweeps found: Valkey, GitLab, and the `docker:29` CI-image pin). This cycle's fresh angle, per STEP 8's "widen the lens" guidance: rather than a fourth currency sweep, checked every `scripts/*.sh` file against `tests/*.bats` for basic coverage — a different class of gap than the prior three passes found. **No prerequisites — executor may pick up immediately.**

Verified directly (not assumed, ADR-0004): grepped every `scripts/*.sh` basename against every `tests/*.bats` file's content. `scripts/forgejo-runner-ensure.sh` was the only script repo-wide with zero references anywhere under `tests/` — its two sibling Forgejo bootstrap scripts, `scripts/forgejo-env-ensure.sh` and `scripts/forgejo-admin-ensure.sh`, each already had an `"<script> exists and is executable"` assertion in `tests/forgejo-compose.bats`; `forgejo-runner-ensure.sh` — called from the same `make forgejo-up` target — was simply missed. This matches ROADMAP rule #9's own named filler example verbatim ("a script with no bats coverage") and CLAUDE.md's "every bugfix must prevent recurrence" mechanical-guard principle.

Added three assertions to `tests/forgejo-compose.bats` (same file as its two sibling scripts' coverage):
1. `"forgejo-runner-ensure.sh exists and is executable"` — mirrors the sibling scripts' exact assertion shape.
2. A structural assertion that the script reads `FORGEJO_ADMIN_PASSWORD` from `forgejo/.env` (not a hardcoded credential).
3. A structural assertion that the registration-token fetch uses `-X GET` (a recurrence guard for the live-discovered `405 Method Not Allowed` on `POST` the script's own inline comment documents — the original fix already shipped, but nothing previously guarded against it silently regressing back to `POST` in a future edit).

Clusterless scope only — no live Docker/Forgejo-instance test was added; the script's actual runtime behavior (registration token exchange, `.runner` file creation) needs a live Forgejo instance to verify, same ADR-0004 ceiling as every other `make forgejo-up`-family script in this repo's test suite. This item adds structural coverage only — zero diff to `scripts/forgejo-runner-ensure.sh` itself.

## PR

https://github.com/tooming/k8s-anywhere/pull/1201
