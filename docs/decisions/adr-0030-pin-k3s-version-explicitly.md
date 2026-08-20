# ADR-0030 — Pin k3s to an explicit version on every backend

**Status.** Adopted. Architect decision, self-authorizing per
[WAYS-OF-WORKING.md](../WAYS-OF-WORKING.md) §0.1/§2 (no binding ADR contradicted — this
is new ground, not a supersession; no existing ADR governs k3s's own version). Applies to
both the localhost (`k3d`) and `oracle` (cloud-init) backends per
[ADR-0026](adr-0026-cloud-agnostic-infrastructure.md).

---

## Context

Every other dependency this lab pins — Cilium, Kyverno, Argo Rollouts, cert-manager, and
23 more — has an ADR recording *why* that version, a `targetRevision`/image tag in
`gitops/`, and a standing seat in the architect routine's weekly upstream-release sweep
(`routines/architect.prompt.md` STEP 1), so a CVE against the pinned version gets caught,
audited, and either kept-with-a-flip-condition or bumped, on record (see, e.g., this
week's own ADR-0020 Re-evaluation log entry, or the Cilium/Kargo CVE bumps in
`docs/done/`). **k3s — the cluster engine itself, the most privileged layer in the whole
stack — has none of that.** Verified directly against the actual bootstrap code (not
assumed, per ADR-0004):

- `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` (the localhost backend, ADR-0026) has
  no `image:` key in its `k3d.io/v1alpha5` `Simple` config — k3d silently uses whatever
  k3s version is bundled with the k3d CLI binary installed on the operator's machine at
  `make up` time.
- `infra/modules/oracle-k3s-cluster/cloud-init.yaml` (the `oracle` backend, ADR-0027)
  installs via `curl -sfL https://get.k3s.io | sh -` with no `INSTALL_K3S_VERSION` set —
  the installer always fetches whatever is current on the `stable` channel at instance
  boot time.
- `docs/decisions/context.md`'s "k3s v1.33.6, 2 nodes" line is a **descriptive snapshot**
  of what one `make up` run happened to install, not an enforced floor — nothing in code
  guarantees the next `make up` (or the next Oracle instance launch) gets the same
  version, or even a version at or past any specific CVE fix line.

This is a genuine gap against two CHARTER Core Values at once: **"Recreate-from-code"**
(`make up` rebuilds the whole lab — but "the whole lab" today excludes a deterministic
k3s version, so two rebuilds months apart are not actually reproducing the same lab) and
**"Clusterless gates stay green"** is necessary but not sufficient here — no clusterless
gate today can catch a k3s CVE, because there is no pinned version for a gate to check
*against*.

**Concrete trigger (this week's architect sweep, 2026-07-19):** CVE-2026-54250 (K3s ZIP
Archive Path Traversal in etcd-snapshot decompression, CVSS 5.8, CWE-22/Zip-Slip — an
administrator restoring a maliciously-crafted snapshot archive can write files outside
the intended directory) affects all versions before `1.33.10`, `1.34.0-rc1`–`1.34.6`, and
`1.35.0-rc1`–`1.35.3`; fixed in `1.33.10`/`1.34.6`/`1.35.3`
([GitLab advisory](https://advisories.gitlab.com/golang/github.com/k3s-io/k3s/CVE-2026-54250/)).
Whether *this lab's* cluster is actually affected is, today, **unanswerable** — not
because the answer is "no", but because nothing in this repo records what version is
actually running. That unanswerability is the real finding, independent of this specific
CVE's severity (admin-triggered, not remote/unauthenticated — a real but not urgent risk
on its own).

---

## Decision

Pin k3s to an explicit, current, stable release on **both** backends — no more
"whatever's current when you happen to bootstrap":

### Version

**`v1.36.2+k3s1`** — verified directly (not assumed):
- Real git tag in `k3s-io/k3s` (also corroborated via a second independent source,
  `newreleases.io`'s release tracker, alongside the latest patches on the still-supported
  `1.34.x`/`1.35.x` lines — `v1.34.9+k3s1`/`v1.35.6+k3s1` — confirming `1.36.2` is
  genuinely the newest stable line, not a stray/pre-release tag).
- The `rancher/k3s:v1.36.2-k3s1` Docker Hub image **directly confirmed to exist**
  (`hub.docker.com/v2/repositories/rancher/k3s/tags/v1.36.2-k3s1` — `tag_status: active`,
  multi-arch `amd64`/`arm64`/`arm`, `last_updated: 2026-06-24`) — a positive registry
  check, not the indirect release-pipeline inference this week's other CVE audit (Argo
  Rollouts, RFC #552) had to fall back to.
- Comfortably past CVE-2026-54250's fix lines (`1.33.10`/`1.34.6`/`1.35.3`) on every
  supported branch, so the pin itself closes that CVE's applicability question for good,
  regardless of what the lab happened to be running before this ADR.

**Tag-format note (a real footgun, worth recording so a future bump doesn't rediscover
it):** the two backends need the *same version* in *different tag formats* — Docker Hub
image tags use a hyphen (`v1.36.2-k3s1`, since `+` is invalid in a Docker tag), while
`INSTALL_K3S_VERSION` (and the upstream GitHub release tag) uses the `+` form
(`v1.36.2+k3s1`, the two-part `<k8s-version>+<k3s-build>` SemVer-with-build-metadata
scheme). A future bump must update both, in both formats, together.

### Mechanism (implementation — ROADMAP item, not this ADR)

- **`k3d` backend:** add a top-level `image: rancher/k3s:v1.36.2-k3s1` key to
  `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` — `image` is a documented top-level
  field of k3d's own `k3d.io/v1alpha5` `Simple` config schema (confirmed against the
  schema's own `image` property definition), sibling to the existing `servers`/`agents`/
  `kubeAPI`/`ports`/`options` keys already in that file.
- **`oracle` backend:** change `curl -sfL https://get.k3s.io | sh -` to
  `curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.2+k3s1 sh -` in
  `infra/modules/oracle-k3s-cluster/cloud-init.yaml`.
- **`docs/decisions/context.md`**: update the "k3s v1.33.6, 2 nodes" line to reflect the
  pin (still a descriptive note, but now describing an enforced floor, not a stale
  snapshot).
- **Recurrence guard**: a clusterless bats test asserting both files reference the exact
  same k3s version (in their respective correct tag formats) — a future bump that
  updates one backend and forgets the other is exactly the kind of drift this repo's
  existing dependency-pin tests (`argo-rollouts.bats`'s `targetRevision` assertions,
  `kyverno.bats`'s, etc.) already guard against for every other component.
- **Governance**: add k3s to `routines/architect.prompt.md` STEP 1's upstream-release
  checklist (`k3s-io/k3s`) — it is already listed there today, so this is confirming
  coverage, not adding it; the gap this ADR closes was the *absence of a pin to check
  the sweep's findings against*, not an absent line in the checklist.

---

## Scope & exceptions

**In scope:** pinning the version string on both backends + the recurrence guard +
the `context.md` note. A single, small, mechanically-verifiable diff.

**Out of scope (explicit, not silently dropped):**
- **Live-cluster verification that a `make up` with this pin actually succeeds.** This
  remote, clusterless session cannot run `make up`/`k3d cluster create`/launch an Oracle
  instance (ADR-0004 — never claim verified-live state that wasn't exercised). The
  maintainer should watch the first post-merge `make up` (localhost) and the next Oracle
  `terragrunt apply` (still blocked on an unrelated Always-Free capacity constraint per
  `infra/live/README.md`'s Status table) before fully trusting this pin in practice.
- **Upgrade automation.** This ADR does not add k3s to the `upgrade-drafter` routine's
  automatic-bump scope (that routine explicitly skips `infra/` per its own constraints) —
  future k3s bumps go through the architect's CVE-sweep + RFC path, same as this one,
  not a routine drive-by version bump. Worth revisiting if that discipline proves too
  slow in practice.
- **A minimum-version *floor* enforced independently of the exact pin** (e.g. "any
  version ≥ 1.33.10 is acceptable"). Rejected as unnecessary complexity: this lab has
  exactly one k3s consumer per backend, not a fleet with staggered upgrade cadences, so
  an exact pin (like every other ADR'd dependency already uses) is simpler and no less
  correct.

---

## Files this work will touch

| Path | Role |
|------|------|
| `docs/decisions/adr-0030-pin-k3s-version-explicitly.md` | This ADR |
| `infra/modules/k3d-cluster/k3d-config.yaml.tftpl` | Add top-level `image:` pin |
| `infra/modules/oracle-k3s-cluster/cloud-init.yaml` | Add `INSTALL_K3S_VERSION=` to the install line |
| `docs/decisions/context.md` | Update the stale "k3s v1.33.6" descriptive line |
| `tests/k3s-version-pin.bats` (new) | Recurrence guard: both backends pin the same version, correct tag format each |

---

## Relationship to existing ADRs

| ADR | Relationship |
|-----|-------------|
| [ADR-0001](adr-0001-gitops-over-terraform-helm.md) | Purely the Terraform bootstrap seam (cluster creation) — this ADR doesn't touch the GitOps/workload layer ADR-0001 governs. |
| [ADR-0004](adr-0004-no-fabricated-content.md) | The version claim and both registry/tag checks in this ADR are directly verified, not assumed; live-`make up` verification is explicitly called out as NOT done (see Scope & exceptions). |
| [ADR-0005](adr-0005-spof-recreate-over-ha.md) | Recreate-from-code depends on the recreate actually being deterministic — an unpinned k3s version undermined that; this ADR closes the gap. |
| [ADR-0026](adr-0026-cloud-agnostic-infrastructure.md) | Both backends now pin the *identical* k3s version — no backend-specific drift, consistent with the cloud-agnostic seam. |
| [ADR-0027](adr-0027-first-cloud-backend-oracle-always-free-k3s.md) | The Oracle backend's `cloud-init.yaml` install line is the concrete file this ADR edits for that backend. |

---

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.

### 2026-07-28 — `v1.36.2+k3s1` pin kept, still current (audit #770)

**Trigger.** This ADR's first re-evaluation since its 2026-07-19 authoring —
verified directly against `k3s-io/k3s`'s real release history
(cross-referenced with `docs.k3s.io/release-notes/v1.36.X`) that `v1.36.2+k3s1`
is still the newest stable k3s release; no `v1.36.3` or `v1.37.0` stable tag
exists yet. Both backend pins (`infra/modules/k3d-cluster/k3d-config.yaml.tftpl`'s
`image: rancher/k3s:v1.36.2-k3s1`; `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s
`INSTALL_K3S_VERSION=v1.36.2+k3s1`) still match each other and the ADR's
original decision — no drift between the two tag formats.

**Decision: Keep.** No new k3s CVE found against the `1.36.x` line beyond
CVE-2026-54250 (already the reason for this pin, and already fixed by it).
**Flip condition:** a new k3s stable release (`v1.36.3+` or `v1.37.x`) ships
with a security fix, or a CVE is disclosed against `v1.36.2` specifically —
either should trigger a bump through the architect CVE-sweep + RFC path this
ADR's own Scope & exceptions section specifies (not a routine drive-by bump).

### 2026-08-05 — bumped to `v1.36.3+k3s1` (RFC #995, ADR audit #994 → Convert)

**Trigger.** The flip condition above was met: `v1.36.3+k3s1` shipped —
verified directly against `k3s-io/k3s`'s real tag list (`git ls-remote --tags`)
and re-confirmed at pickup time, not just at RFC-authoring time. `git log
v1.36.2+k3s1..v1.36.3+k3s1` on a real clone contains commit `11f5071f57`
("Redact single-dash secret flags in the node args annotation") — the
`k3s.io/node-args` annotation's redaction logic previously only matched
double-dash secret flags, letting a single-dash secret flag's value leak in
plaintext into a `Node` object annotation readable by anyone with `get`/`list`
RBAC on `nodes`. No formal CVE/GHSA is attached to this specific commit
(checked GitHub's published security advisories for `k3s-io/k3s` directly —
none matches), but it is a genuine credential-exposure fix — satisfying this
ADR's flip condition ("ships with a security fix"), which is explicitly
broader than "a CVE is disclosed." No breaking changes in the range (the rest
is routine dependency bumps — etcd, Traefik, CoreDNS, Metrics Server, spegel,
kine, dynamiclistener — plus CI/build chores).

**Decision: Convert (bump).** Pinned `v1.36.3+k3s1` on both backends:
`infra/modules/k3d-cluster/k3d-config.yaml.tftpl`'s `image:
rancher/k3s:v1.36.3-k3s1`; `infra/modules/oracle-k3s-cluster/cloud-init.yaml`'s
`INSTALL_K3S_VERSION=v1.36.3+k3s1`. Both tag formats moved together, per this
ADR's own footgun note. `docs/decisions/context.md`'s descriptive k3s line
updated to match. Full audit trail: [ADR audit
#994](https://github.com/tooming/k8s-anywhere/issues/994), [RFC
#995](https://github.com/tooming/k8s-anywhere/issues/995).

**ADR-0004 caveat, per this ADR's own Scope & exceptions (unchanged):** this
remote, clusterless session cannot verify a `make up`/Oracle bootstrap with
this pin succeeds end-to-end — the maintainer should watch the first
post-merge `make up` and the next Oracle `terragrunt apply` before fully
trusting this pin in practice.

**Flip condition (next re-evaluation):** a new k3s stable release at or above
`v1.36.3` ships with a security fix, or a CVE is disclosed against `v1.36.3`
specifically — same architect CVE-sweep + RFC path, not a routine drive-by
bump.

### 2026-08-20 — `v1.36.3+k3s1` pin kept, still current, GHSA sweep clean (audit #1281)

**Trigger.** This ADR's last audit (2026-08-05, the bump above) was two weeks
stale relative to today, and this run's earlier 2026-08-19 GHSA-sweep round
covered most other ADR'd components (ArgoCD, Garage, Cilium, Istio, Longhorn,
Velero, Trivy Operator, Kargo, cert-manager, KEDA, External Secrets) but not
k3s itself — architect-fallback cycle (`executor.prompt.md` STEP 6b) picked
this ADR as the genuinely stalest-audited one.

**Verified directly (not assumed, ADR-0004):** `git ls-remote --tags
k3s-io/k3s` confirms `v1.36.3+k3s1` — the pin both backends already carry
(`infra/modules/k3d-cluster/k3d-config.yaml.tftpl`'s `image:
rancher/k3s:v1.36.3-k3s1`) — is still the newest tag on the `1.36.x` line; no
`1.37.x` line exists yet. Fetched `github.com/k3s-io/k3s/security/advisories`
directly: three published advisories total.
- **GHSA-jxr7-mqhw-9p98** (Moderate, CVSS 5.8, ZIP path-traversal in etcd
  snapshot decompression, published June 2026) — fetched the advisory itself
  for exact ranges: affected `<=v1.35.2+k3s1` / `<=v1.34.5+k3s1` /
  `<=v1.33.9+k3s`, fixed at `v1.35.3+k3s1` / `v1.34.6+k3s1` /
  `v1.33.10+k3s1`. This lab's pin is on a newer minor line entirely than
  every affected range.
- **GHSA-m4hf-6vgr-75r2** (High, apiserver TLS-SAN-stuffing unauthenticated
  DoS, 2023) and **GHSA-cxm9-4m6p-24mc** (Moderate, empty-token
  bootstrap-data encryption, 2021) — both pre-date this pin by years,
  already accounted for by prior audits.

**Decision: Keep.** No new k3s release and no applicable CVE against the
`1.36.x` line. Full audit trail: [ADR audit
#1281](https://github.com/tooming/k8s-anywhere/issues/1281).

**Flip condition (next re-evaluation):** unchanged — a new k3s stable release
at or above `v1.36.3` ships with a security fix, or a CVE is disclosed
against `v1.36.3` specifically.
