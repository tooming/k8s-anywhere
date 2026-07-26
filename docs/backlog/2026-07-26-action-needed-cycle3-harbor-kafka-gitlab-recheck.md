# [Action needed] Now/next still gated; Harbor CVE already mitigated, third CVE batch clean

## What's blocked

The five remaining `[ ]` items in ROADMAP.md's *Now / next* are all gated on
the standing maintainer-confirmation issues #631/#632/#633 — re-verified this
cycle (third cycle of 2026-07-26): all three still open, zero comments.

## This cycle's fresh angle

Continuing this run's CVE-specific verification lens (see the two prior
dated files in this directory) to a third batch: GitLab (self-hosted, the
lab's own SCM/CI), Harbor, the Aiven Inkless Kafka broker's pinned client
image, and Garage.

**Notable finding, already mitigated: CVE-2026-4404 (Harbor default
credentials, CVSS 9.4 Critical, GHSA-hj7x-hmf2-hc2p)** — affects Harbor ≤
2.15.0 (hardcoded `admin`/`Harbor12345` web-UI credentials), fixed in 2.15.1.
This repo's Harbor chart pin (`1.19.1`, confirmed via the chart's own GitHub
release notes to package Harbor OSS **v2.15.1**) is exactly the fixed version.
**Independently of the version match, this lab was never exposed to begin
with**: `gitops/platform/harbor.yaml` sets `existingSecretAdminPassword:
harbor-admin-creds` rather than relying on the chart's default, and
`gitops/secrets/harbor-admin-externalsecret.yaml` sources that Secret from
Vault path `secret/harbor/admin`, seeded by `scripts/vault-bootstrap.sh` with
`admin-password="$(openssl rand -hex 16)"` — a random credential, never the
literal `Harbor12345` default, generated before Harbor is ever brought up.
The file's own header comment already documents this exact rationale
("replacing the hard-coded default password Harbor12345 with a
Vault-generated random credential"), so this is a pre-existing, deliberate
mitigation, not something built this cycle. (Harbor is also still
non-auto-synced/not deployed per ADR-0024 and issue #632's open footprint
gate, so live exposure is zero regardless.)

**Remaining components checked:**

| Component | Pinned version | CVE checked | Verdict |
|---|---|---|---|
| GitLab CE | `gitlab/gitlab-ce:latest` (`gitlab/docker-compose.yml`) | general 2026 GitLab CVE landscape | not a version-pin gap by design — this image floats on `latest`, so any released GitLab security fix is already the next `docker compose pull`, not a pin this executor can bump; no action available |
| Apache Kafka client (Inkless traffic-gen) | image `apache/kafka:3.9.2` | CVE-2026-35554 (producer buffer-pool race condition causing message misrouting, CVSS 8.7, affects ≤3.9.1/≤4.0.1/≤4.1.1, fixed 3.9.2/4.0.2/4.1.2/4.2.0) | current — `3.9.2` is exactly the fixed version on the 3.9.x line |
| Garage | image `dxflrs/garage:v2.3.0` | searched for a Garage-specific 2026 CVE | none found — Garage has no disclosed security advisories to date; not a confirmed gap, just no finding either way |

No actionable version gap or unmitigated exposure found this cycle either.

## What would unblock further work

Unchanged: (a) maintainer confirmation on #631/#632/#633; (b) a new upstream
CVE/release firing a tracked ADR flip condition; (c) a new GitHub issue of any
size. The remaining lower-risk components not yet CVE-swept this run (`kro`,
`ack-s3`, Alloy, Pyroscope, node-exporter, moto) are candidates for a future
cycle's continuation of this lens if no higher-value angle turns up first.

This note is this cycle's honest record — a third, distinct CVE-research
batch confirming an existing mitigation rather than assuming safety from a
version number alone — not a stopping point. The run continues to the next
cycle per `executor.prompt.md` STEP 8.
