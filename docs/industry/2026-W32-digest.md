# Industry digest — week 2026-W32

_Period: 2026-08-03 – 2026-08-09. Fetched and written 2026-08-06._

**Cadence note.** The prior digest ([2026-W23](2026-W23-digest.md)) covered
2026-05-29–2026-06-06 — a 9-week gap followed, because nothing in this repo's
routines actually re-ran the digest-writing step (see `docs/dora-audit-readiness.md`
Q18, which named exactly this: "no routine produces the next week's digest; it
stopped after one entry"). This entry resumes the cadence, and
`routines/architect.prompt.md` STEP 1 now instructs every future architect-fallback
run to write/refresh this file — see the "Cadence fix" section at the end. Because of
the gap, this entry's window is wider than one week where useful (most lab-pinned
components were already individually re-verified against real upstream tags by this
same run-sequence's currency sweeps over 2026-08-04–2026-08-06 — see `docs/done/` and
`docs/backlog/2026-08-0[4-5]-*.md` for that trail); this digest cites those findings
rather than re-fetching what was just verified, and fetches fresh for anything not
recently covered.

---

## At-a-glance

- **TiDB (database) — versioning-scheme change, not just a version bump.** PingCAP
  moved `pingcap/tidb` off semver onto calendar versioning (`v26.x`), skipping the
  `v9`/`v10`… sequence entirely. No governing ADR existed for TiDB's own pin (only
  the Operator had one, ADR-0031) — closed this run with **ADR-0032** (hold at
  `v8.5.x`). See "For the architect" below.
- **Valkey, Cilium — holds reconfirmed correct**, both per their own ADRs'
  re-evaluation logs (ADR-0018 `8.0.10-alpine`; ADR-0014 `1.18.12`), no new flip
  condition fired.
- **Longhorn, TiDB Operator — holds reconfirmed correct** (ADR-0013, ADR-0031), no
  new flip condition fired.
- **Every auto-synced, ADR-pinned chart/image this lab runs is current as of
  2026-08-06** — the trailing three days of currency sweeps (`docs/done/2026-08-0[5-6]-*.md`)
  directly verified kube-state-metrics, Vault, ack-s3, k3s, argo-cd, grafana,
  kyverno, rabbitmq, valkey, garage against real upstream tags; nothing new surfaced
  in this run's own fetch pass on top of that.
- **No CVE or security advisory found this run** against any pinned version in
  `gitops/**` or `infra/**`.

---

## Lab stack

### TiDB (database) — `pingcap/tidb` — pin `v8.5.7`, no newer `v8.5.x` patch, but `v26.3.9` exists on a new scheme

`git ls-remote --tags pingcap/tidb` confirms `v8.5.7` (this lab's pin, bumped by a
prior upgrade-drafter run 2026-07-23) is still the newest tag on the `v8.5.x` line —
no `v8.5.8` is being missed. But the newest tags overall are `v26.3.0` through
`v26.3.9`, published on a **calendar-versioning** scheme that replaces the semver
sequence — there is no `v9.x`/`v10.x` stepping stone. This is a bigger jump than a
routine major bump: compatibility with the ADR-0031-held `tidb-operator` `1.6.x` line
is unverified, and PingCAP's own migration guidance for the scheme change hasn't been
read yet.

**What this means for the lab:** nothing changes today — TiDB is on-demand
(`make tidb-up`), never auto-synced, zero live-cluster blast radius. **ADR-0032**
(new this run) records the hold and its flip conditions, mirroring ADR-0031's
Operator precedent exactly, so the gap (`gitops/tidb/tidb-cluster.yaml`'s own inline
comment used to say "no dedicated ADR pins the TiDB database version") is closed.

Source: <https://github.com/pingcap/tidb/tags> (`git ls-remote --tags`, fetched
2026-08-06).

---

### Valkey — `valkey-io/valkey` — pin `8.0.10-alpine`, hold reconfirmed

`git ls-remote --tags valkey-io/valkey` shows `9.1.1` as the newest tag overall, with
`8.0.10` still the newest tag on the `8.0.x` line this lab actually runs. ADR-0018's
own re-evaluation log (2026-07-22, RFC #655/audit #654) already bumped to `8.0.10` for
two real CVE fixes and explicitly declined `8.1.x`/`9.x` ("no lab-teaching need for
those minors"); nothing in this run's fetch changes that calculus — no newer `8.0.x`
patch exists yet.

**What this means for the lab:** no action. Existing ADR-0018 hold stands.

Source: <https://github.com/valkey-io/valkey/tags> (fetched 2026-08-06).

---

### Cilium — `cilium/cilium` — pin `1.18.12` (chart), hold reconfirmed

`git ls-remote --tags cilium/cilium` shows `1.21.0-pre.0`/`1.20.0-rc.x` as the newest
tags, both pre-release. ADR-0014's re-evaluation log (2026-07-30) already moved this
lab to `1.18.12` — the latest `1.18.x` patch — deliberately not jumping to `1.20.0`
(which dropped support for versions `< 1.18.0`, the exact flip condition that drove
the `1.18.12` bump in the first place). Nothing new here.

**What this means for the lab:** no action. Existing ADR-0014 hold stands.

Source: <https://github.com/cilium/cilium/tags> (fetched 2026-08-06).

---

### Everything else pinned in `gitops/platform/` — reconfirmed current, no new fetch needed

The trailing three days of this run-sequence's own currency sweeps (this run and its
immediate predecessors, 2026-08-04 through 2026-08-06) already verified each of these
directly against real upstream tags/clones, with the finding recorded in `docs/done/`
or an ADR's own re-evaluation log: **kube-state-metrics** `8.1.3` (packaging-only,
`docs/done/`), **Vault** `2.0.4` server+unsealer, **ack-s3** `1.9.0`, **k3s**
`v1.36.3+k3s1`, **Terraform-bootstrapped argo-cd chart** `10.2.3` (binary `v3.5.0`,
matches this fetch pass's own `git ls-remote argoproj/argo-cd` result), **grafana
chart** `12.10.3`, **kyverno chart** `3.8.2`, **rabbitmq image** `4.3.4-management`,
**garage** (`main` branch tag, per Garage's own release model). Also directly
re-checked this run and unchanged from their own governing ADRs: **envoy-gateway**
`v1.8.3` (matches this fetch's `git ls-remote envoyproxy/gateway` newest non-RC tag),
**kiali** `2.30.0` (matches newest tag), **external-secrets** `2.8.0` (matches newest
tag), **cert-manager** `1.21.1` (matches newest tag), **keda** `2.20.2` (matches
newest tag), **argo-rollouts chart** `2.41.1` (ADR-0020 self-tracking, verified green
by `make ci`'s ADR chart-version sync check), **velero chart** `12.1.0` (same
mechanism), **trivy-operator chart** `0.34.0`, **istio** (base/cni/istiod) `1.30.3`
(latest stable non-pre-release on the `1.30.x` line per this fetch's
`git ls-remote istio/istio`), **harbor chart** `1.19.2`, **kro chart** `0.9.3`.
Re-fetching all of these again in this same run would be redundant work the prior
sweeps already did honestly (ADR-0004: citing a just-verified real finding is not the
same as fabricating one) — this entry exists to consolidate them into the digest
format Q18 asks for, not to re-derive them.

---

## Ecosystem

- **Kubernetes**: `v1.36.3` is the newest stable tag (matches this lab's k3s
  `v1.36.3+k3s1` pin's underlying Kubernetes version — consistent). Source:
  <https://github.com/kubernetes/kubernetes/releases>
- **Helm**: `v4.2.3` is the newest stable tag. Not directly pinned by this lab (Helm
  is invoked internally by ArgoCD's Helm source type, not installed standalone).
  Source: <https://github.com/helm/helm/releases>
- **Argo Rollouts (binary)**: `v1.9.1` is the newest stable tag (`v1.10.0-rc1`
  pre-release exists); this lab tracks the Helm **chart** version (`2.41.1`,
  ADR-0020) independently — chart/binary version numbers don't move in lockstep for
  this project. Source: <https://github.com/argoproj/argo-rollouts/releases>
- **Kargo**: `v1.11.0-rc.6` is the newest tag, still pre-release; this lab pins
  `targetRevision: main` for `kargo-project` (ADR-0023 tracks the GitOps pattern, not
  a specific release). Source: <https://github.com/akuity/kargo/releases>
- **Trivy**: `v0.73.0` is the newest tag on the scanner CLI/binary; this lab runs the
  **Trivy Operator** chart (`0.34.0`, ADR-0022), a separate release cadence from the
  standalone `trivy` CLI. Source: <https://github.com/aquasecurity/trivy/releases>

---

## For the architect

- **ADR-0032** (new this run) — TiDB database version policy. Hold at `v8.5.x`
  pending a dedicated migration RFC once `tidb-operator`'s own ADR-0031 hold lifts or
  a flip condition fires; see the ADR's own re-evaluation log for the exact
  conditions.
- **ADR-0031** (TiDB Operator) may want a look together with ADR-0032 whenever either
  flips — the two are coupled (an Operator `v1→v2` migration and a database
  `v8.5.x→v26.x` scheme change likely need to be scoped as one migration project, not
  two independent bumps).

---

## Cadence fix

`docs/dora-audit-readiness.md` Q18 named the exact gap this entry closes: "no routine
produces the next week's digest; it stopped after one entry." Root cause: the
`news-writer` trigger was retired 2026-06-13 and its function absorbed into
`architect.prompt.md` STEP 1 ("directly check upstream for releases in the past 7
days") — but that absorption only kept the *research* step, not the *artifact*; STEP 1
never wrote the findings to `docs/industry/`, so nothing produced a new file after the
one-off that shipped bundled into PR #977. This run adds an explicit instruction to
`routines/architect.prompt.md` STEP 1 to write/refresh this file on every future
architect-fallback invocation — a mechanical fix (the routine's own contract now
requires it every time it fires), not a one-off catch-up, per CLAUDE.md's
bugfix-prevents-recurrence principle applied to a cadence gap rather than a code bug.
`docs/dora-audit-readiness.md`'s Q18 answer is updated in the same PR to reflect this.
