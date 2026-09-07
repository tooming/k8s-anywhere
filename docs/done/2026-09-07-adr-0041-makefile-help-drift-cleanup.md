# JANITOR-fallback: post-2026-09-06-removal-wave Makefile help-text drift + dead `keda-up`/`keda-down` targets cleaned up; readme-check's ADR exemption gap closed

**The class of bug.** The 2026-09-06 removal wave (TiDB, Istio ambient mesh +
Kiali, Longhorn, RabbitMQ, Valkey, KEDA, the entire observability stack —
ADR-0041 and friends) correctly updated the underlying scripts and most docs,
but left several `Makefile` `##` help-text lines and one set of real Makefile
targets stale/dead:

- `capstone-demo` help text still promised a "Tempo trace" step — removed from
  `scripts/capstone-demo.sh` and `tests/capstone-demo.bats` 2026-09-06, but the
  `Makefile`'s own one-line summary was never updated to match.
- `context-doc-version-sync-check` help text still said it tracks "Grafana,
  Pyroscope, KRO" — the script itself only tracks KRO and ACK s3-controller
  now (Grafana/Pyroscope citations were removed from `docs/decisions/context.md`
  the same day).
- `coredns-nip-io-rewrite` help text still said "Envoy Gateway's proxy Service"
  — `scripts/coredns-host-alias.sh` itself was already correctly updated to
  Traefik (ADR-0040) months earlier; only this one Makefile comment lagged.
- `ondemand-budget-check` help text still listed "Harbor/Istio/Kiali/Longhorn/
  Kargo/TiDB" as live on-demand units — the script itself already correctly
  tracks only Harbor and Kargo as live, with the others kept purely as
  historical orphan-detection carve-outs (confirmed by reading the script
  directly, not assumed).
- **Real dead code, not just stale text:** `keda-up`/`keda-down` Makefile
  targets still existed, calling `argocd-sync`/`argocd-delete` against
  `keda-extras`/`keda`/`keda-networkpolicy`/`data-demo-keda-scaling` — none of
  which exist anywhere under `gitops/` any more (confirmed via a repo-wide
  grep). Worse: **ADR-0029's own Status line explicitly claimed** "`keda-up`/
  `keda-down` Makefile targets... were deleted in the same change" as KEDA's
  2026-09-06 removal — a false claim (ADR-0004) that had gone unnoticed
  because nothing checked it. These targets would have failed the instant
  anyone ran them, silently promising functionality that no longer exists.

**Fix.** Reworded the four stale help-text lines to match each script's real,
current behavior. Deleted the dead `keda-up`/`keda-down` targets entirely —
this makes ADR-0029's Status-line claim true for the first time.

**The mechanical-guard gap this uncovered.** Deleting the dead targets then
broke `make readme-check` on the real repo: `scripts/readme-check.sh`'s rule
#4 ("every `make X` an ADR mentions must exist in the Makefile") already
exempted **Superseded by**-status ADRs (their historical prose is expected to
go stale), but had no equivalent exemption for **Removed**-status ADRs — a
newer status shape introduced for components dropped entirely with no
replacement (TiDB, Istio, Longhorn, RabbitMQ, Valkey, KEDA). ADR-0029's own
historical narrative (describing the 2026-08-25 conversion to on-demand,
before the 2026-09-06 full removal) still mentions `make keda-up`/`make
keda-down` by name, exactly the same "true when written, not current live
state" shape the Superseded-by exemption already covers. Extended the
exemption regex to `**Status.** (Superseded by|Removed)`, with new regression
coverage: `tests/drift-readme-check-removed-status.bats` (its own file per
`tests/drift-detectors.bats`'s "new coverage goes in its own file"
convention) + a matching fixture tree under
`tests/fixtures/readme-check-removed-status/`.

**Verification.** `make ci` ran fully clean (exit 0, zero `not ok` lines) both
before removing the dead targets (confirming the starting point) and after
every fix landed, including the new regression test. Behavior-preserving:
no `make`-invocable behavior changed except removing two provably-dead
targets; every other check's pass/fail outcome is unchanged.

Found via the executor's STEP 6b JANITOR fallback (this run's fifth
consecutive cycle with a fully-gated "Now / next" lane — tried yet another
lens per STEP 8's "widen it" guidance: sweeping Makefile `##` help text for
leftover references to the 2026-09-06 removal wave, after currency checks and
the prior bats-shellcheck cleanup had already been tried this run).

## PR

(filled in once the PR is opened)
