# ADR-0002 — Garage for S3-compatible storage (not MinIO)

**Decision.** Use **Garage** as the in-cluster S3-compatible object store. Do NOT
use MinIO.

**Why.** MinIO gutted its open-source offering (removed console features,
community backlash) around 2025 — considered "dead" for this purpose. Garage is a
lightweight, actively-maintained Rust S3 store. SeaweedFS is an acceptable
fallback; Rook-Ceph RGW is too heavy for a 16 GB lab.

**Use.** Backs Mimir (blocks/ruler) and Loki; will receive Longhorn backups if
Longhorn is ever added. Distinct from moto's S3 (moto = AWS-API/IaC learning;
Garage = real workload storage). Bootstrap (layout/key/buckets) is imperative via
the `garage` CLI — see `scripts/garage-bootstrap.sh`.

**Status.** Adopted. Deployed in `storage` ns; S3 verified.

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-08-19 — `v2.3.0` pin re-kept; upstream org-slug bug found and fixed (executor JANITOR pass, cycle 17)

**Trigger.** Routine currency re-check of Garage as part of a JANITOR-fallback
sweep (`executor.prompt.md` STEP 6b, reached after PLANNER/ARCHITECT/UPGRADE-
DRAFTER/DOC-DRIFT-AUTHOR/TRIAGER all found nothing new this cycle — the "Now /
next" lane was re-confirmed gated on issue #633, unchanged).

**Finding.** `docs/dependency-register.md`'s Garage row (and this same repo
slug hardcoded into `routines/architect.prompt.md`'s STEP 1 upstream-release
list) pointed at `github.com/Deuxfleurs/garage` — a dead URL, confirmed via a
direct fetch (HTTP 404, no redirect). The real org is `deuxfleurs-org`
(`github.com/deuxfleurs-org/garage`, confirmed reachable via `git ls-remote`).
This is a real, already-present footgun: the architect routine's own STEP 1
literally runs `gh release list --repo deuxfleurs/garage` every week using
this same wrong slug (missing the `-org` suffix), meaning every past architect
run attempting to check Garage's release history against this line would have
hit a nonexistent repo rather than a real currency check — invisible to
`make ci`'s `markdown-links-check` because that check only follows proper
`[text](path)` internal links, by design excluding bare external URLs like
this one (network-dependent reachability is explicitly out of its scope).

**Decision: Keep the `v2.3.0` pin, fix the org slug.** Re-verified directly
against the *correct* URL: `github.com/deuxfleurs-org/garage/security/
advisories` lists zero published advisories, and `git ls-remote --tags` shows
`v2.3.0` (this lab's pin in `gitops/storage/garage/statefulset.yaml`) is still
the newest stable tag — same conclusion the 2026-07-28 audit reached, now
verified against a URL that actually resolves. Corrected the slug in both
`docs/dependency-register.md` and `routines/architect.prompt.md`'s STEP 1
list, and added a pinned-value regression guard (`tests/dependency-
register.bats`) asserting the dead `Deuxfleurs/garage` (any casing without
`-org`) slug never reappears in either file. **Flip condition:** a new Garage
stable release ships with a security fix, or a CVE is disclosed against
`v2.3.0` specifically.

### 2026-07-28 — `v2.3.0` pin kept, still current (audit #776)

**Trigger.** First re-evaluation of this ADR's own audit trail (Garage's
currency was informally checked in a prior run's
`docs/backlog/2026-07-27-action-needed-argo-rollouts-eso-garage-sweep.md`
note, but never recorded against this ADR).

**Decision: Keep.** Verified directly against `Deuxfleurs/garage`'s real
release history: `v2.3.0` (released 2026-04-16, this lab's pin in
`gitops/storage/garage/statefulset.yaml`) is still the newest stable release —
no newer tag exists. No CVE found against Garage in any version. **Flip
condition:** a new Garage stable release ships with a security fix, or a CVE
is disclosed against `v2.3.0` specifically.
