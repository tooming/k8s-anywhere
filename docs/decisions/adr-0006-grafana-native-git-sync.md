# ADR-0006 — Dashboards via Grafana native Git Sync (not the sidecar)

**Decision.** Manage Grafana dashboards with Grafana's **native Git Sync**, replacing
the k8s-sidecar + labelled-ConfigMap delivery. Git Sync points at the lab's own
**GitLab** via the OSS **Pure Git** repository type, so dashboards stay versioned in
the existing source of truth. Sync is **bidirectional**: edits in the UI are committed
back to GitLab, and changes in GitLab appear in Grafana.

**Why.** The sidecar path is one-way (git→cluster): UI edits are lost on restart, and
every dashboard must be wrapped as JSON-in-YAML inside a ConfigMap (friction + size
limits). Git Sync stores plain dashboard JSON in git, gives real history/diffs, and
makes "dashboards as code" the live workflow — the upstream-blessed observability-as-code
path, and exactly the kind of real-platform mechanism this lab exists to learn (ADR-0003).

**Relationship to ADR-0001 (explicit carve-out).** ADR-0001 stands: **ArgoCD remains the
sole reconciler for in-cluster workloads**, including Grafana itself and its Helm config.
ADR-0006 carves out **one scoped exception** — dashboard *content* is reconciled by
Grafana's own Git Sync loop, not ArgoCD. This is acceptable because dashboards are
content/data, not infrastructure; **GitLab stays the single source of truth** (the spirit
of ADR-0001 is preserved — only the reconciler differs); and the second loop is bounded
to dashboards. No new dependency cycle: Grafana↔GitLab does not touch ArgoCD's repo
credentials or Vault's unseal key (ADR-0001 corollary).

**Specifics.**
- Requires Grafana **v12.4+** (the generic `git` provider) with the `provisioning` +
  `kubernetesDashboards` toggles, `[provisioning] repository_types` allow-listing `git`,
  and a one-time `unified_storage … enableMigration` for the existing dashboards. The
  Pure-Git / self-hosted path is new (Feb 2026), flagged not-for-prod — an accepted
  learning-lab risk, not a production claim (ADR-0004).
- **HTTPS is mandatory** — Pure Git rejects `http://`. The http-only lab GitLab is fronted
  by an **nginx TLS proxy** (`:8930`, mkcert cert); Grafana trusts the mkcert CA via a
  combined bundle (init container + `SSL_CERT_FILE`). ArgoCD/CLI keep using http `:8929`.
- **Pure Git** type (OSS). The *enhanced* GitLab integration (PR workflows, linking) is
  Enterprise/Cloud-only and is **not** used.
- Auth = a **GitLab Personal Access Token** kept in **Vault** (the existing api-scoped
  bootstrap token) and read by the Git Sync bootstrap seam, which hands it to Grafana via
  the Repository's `secure.token` (stored encrypted *inside* Grafana). No workload reads
  it at runtime, so no ExternalSecret is needed — the token never lands in git either way.
- Removes on cutover: the k8s-sidecar dashboard config, the sidecar dashboard
  ConfigMaps, and the `observability-dashboards` ArgoCD Application. **Community
  dashboards (gnetId) are unaffected** — separate provider.

**Status.** **Adopted.** Implemented + verified live at `13.0.1`: Grafana synced the
lab dashboards (`grafana/dashboards/` in the repo) from GitLab over the TLS proxy; the
k8s-sidecar, dashboard ConfigMaps, and the `observability-dashboards` app are removed.
The pin is now `13.0.3` (2026-07-19, CVE bump — see §Re-evaluation log); the
entrypoint script driving this Git Sync path was diffed byte-for-byte between
`v13.0.1` and `v13.0.3` (identical) as part of that bump, but live re-verification of
the sync flow at `13.0.3` on a real cluster is still pending the maintainer's next
`make up` (this repo runs remotely and clusterless — ADR-0004).
The Repository connection is bootstrapped imperatively (`scripts/grafana-gitsync-bootstrap.sh`),
the TLS proxy + CA via `scripts/gitlab-tls-bootstrap.sh`. Community (gnetId) dashboards
are unaffected. Both bootstraps are wired into `make up` (`Makefile`'s `up` target calls
`gitlab-tls-bootstrap` then `grafana-gitsync-bootstrap`).

## Re-evaluation log

ADR audits (the architect routine's STEP 2) record their outcome here when the
decision is **kept**. An audit terminates in a documented decision — not only
when something changes — so a finding that survives review leaves a dated
trail and an explicit *flip condition* instead of an open issue that lingers.
No dedicated ADR exists for Loki/Tempo individually (they're part of the
always-on LGTMP stack) — their audit results are recorded here as the closest
Grafana-stack home.

### 2026-07-18 — Grafana / Loki / Tempo CVE sweep kept (audit #518)

**Trigger.** Routine CVE sweep of the observability stack:
- **Grafana** (`13.0.1`): CVE-2026-27876 (critical RCE via SQL Expressions + an
  Enterprise plugin, CVSS 9.1) affects `11.6.0`–`12.4.2`; "13.0.0 and above are
  not affected" per the vendor advisory. CVE-2026-21720 (avatar-cache
  goroutine-leak DoS) was fixed in the `release-12.0.9` backport, well below
  this lab's line. Neither applies at `13.0.1`.
- **Loki** (`3.7.2`, `gitops/observability/loki/deployment.yaml`):
  CVE-2026-21726 (Ruler API double-encoded path traversal) affects versions
  before `3.6.4`, fixed in `3.6.4`+. `3.7.2` already carries the fix.
- **Tempo** (`2.10.5`, `gitops/observability/tempo/deployment.yaml`):
  CVE-2026-28377 (S3 SSE-C key exposure via `/status/config`) affects versions
  before `2.10.3`, fixed in `2.10.3`+. CVE-2026-27878 (TraceQL exemplars-hint
  OOM) and CVE-2026-21728 (unbounded `max_result_limit` OOM, default fixed to
  `262144` from `2.9` on) were both fixed at `2.8`/`2.9`. `2.10.5` carries all
  three fixes, and this lab's Tempo config does not override
  `search.max_result_limit` to reintroduce the unsafe pre-`2.9` default.
- CVE-2026-10601 / CVE-2026-42129 (Loki/Tempo *datasource plugin* path
  traversal — a Viewer reaching unintended backend endpoints) live in
  Grafana's bundled datasource-plugin code, not the Loki/Tempo server. This
  audit did not find a confirmed-fixed Grafana version for this specific CVE
  pair — **not resolved as "not applicable"**, only as "no groundable action
  found this run."

**Decision: keep pins `grafana:13.0.1`, `loki:3.7.2`, `tempo:2.10.5`.** All
three version-specific CVEs found are already fixed at the current pins.

**Flip condition.** Revisit Grafana's pin specifically once a fixed-version
citation for CVE-2026-10601/CVE-2026-42129 is found (re-run the search then);
revisit Loki/Tempo when a new bulletin names a version at or above the
current pins as affected.

### 2026-07-19 — Grafana flip condition met, pin bumped (audit #562, RFC #563)

**Trigger.** The flip condition above was met: fetching Grafana's own real
`CHANGELOG.md` at the `v13.0.2` git tag (via `raw.githubusercontent.com`) found
the fixed-version citation audit #518 was waiting for — `13.0.2` (2026-06-09)
lists `CVE-2026-10601` and `CVE-2026-42129` among seven CVEs it fixes (the other
five — `CVE-2026-9029`, `CVE-2026-33382`, `CVE-2026-42127`, `CVE-2026-8609`,
`CVE-2026-8595` — were not in audit #518's scope, which only checked the three
CVE families it had a citation for at the time). A distinct `v13.0.1+security-01`
Docker Hub tag (different commit SHA than plain `v13.0.1`) independently
corroborated an out-of-band security backport existed for the prior pin.

**Decision: bump `grafana:13.0.1` → `13.0.3`** (the newest `13.0.x` patch,
smallest safe delta carrying every known fix). Loki (`3.7.2`) and Tempo
(`2.10.5`) are unaffected by this audit — their own flip conditions
(a new bulletin naming a version at or above their current pins) were not
triggered this pass.

Implemented via [RFC #563](https://github.com/tooming/k8s-anywhere/issues/563)
→ `auto/grafana-cve-bump-13-0-3` (`gitops/platform/observability-grafana.yaml`'s
`image.tag` override; chart `targetRevision` unchanged). See
`docs/done/2026-07-19-grafana-cve-bump-13-0-3.md` for the full verification
record (including the `packaging/docker/run.sh` byte-diff re-confirming this
ADR's `readOnlyRootFilesystem` write-path analysis still holds at the new pin).

**Flip condition (next re-evaluation).** Revisit Grafana's pin again when a new
bulletin names a version at or above `13.0.3` as affected. Loki/Tempo flip
conditions from audit #518 remain unchanged (unmet).

### 2026-07-28 — flip conditions re-checked, all three pins kept (executor currency check)

**Trigger.** Periodic re-check of the two outstanding flip conditions above
(Grafana's from audit #562, Loki/Tempo's from audit #518), as part of this
run's broader ADR re-evaluation sweep (this ADR had the oldest re-evaluation
entry — 2026-07-19 — of any ADR in the repo at the time this check started).

**Re-checked directly against live sources (ADR-0004):** GitHub Security
Advisories for `grafana/grafana`, `grafana/loki`, and `grafana/tempo`. No new
advisory naming a version at or above the current pins (`13.0.3`, `3.7.2`,
`2.10.5` respectively) was found in any of the three. `grafana/loki` currently
has zero published security advisories at all; `grafana/tempo`'s only listed
advisory (`GHSA-fx6q-qhch-hxgp`) is unrelated to this version range.

**Decision: kept `grafana:13.0.3`, `loki:3.7.2`, `tempo:2.10.5`.** None of the
three flip conditions fired. No repo change this cycle.

**Flip condition (next re-evaluation).** Unchanged from the prior entries above.

### 2026-08-06 — Loki security fix range found, pin bumped `3.7.4` → `3.7.5`

**Log-drift note.** This entry also catches up a gap: the live pin
(`gitops/observability/loki/deployment.yaml`) had already moved to `loki:3.7.4`
by the time this run started — a routine bump that landed without a matching
entry here (the audit trail above stops at `3.7.2`, 2026-07-28). No `docs/done/`
record of that intermediate bump was found either. Noting the gap honestly
rather than silently re-dating the log to make it look continuous — the pin
itself was never wrong, only this ADR's own tracking of it lagged.

**Trigger.** Fresh currency sweep (this run's second cycle, `executor.prompt.md`
rule #9 judgment — Now/next's three items remain gated on #631/#633, unchanged;
PLANNER/ARCHITECT fallback passes this run found no ungroomed issues, no
un-RFC'd 🟡 items, and no new ADR-audit triggers beyond what this run's first
cycle already resolved — see ADR-0032/`docs/industry/2026-W32-digest.md`). A
full inventory of every `image:` line under `gitops/` (not just ArgoCD
`Application` `targetRevision`s) found `grafana/loki:3.7.4` one patch behind
the real newest tag.

**Verified directly (not assumed, ADR-0004):** `git ls-remote --tags
grafana/loki` shows `v3.7.5` as the newest tag on the `3.7.x` line pinned here
(no major/minor jump). A real clone's commit range `v3.7.4..v3.7.5` (25
commits) contains genuine security fixes, not just routine chores: six
`[SECURITY]`-tagged dependency bumps — `github.com/klauspost/compress` →
`v1.18.7` (three separate module paths), `golang.org/x/text` → `v0.39.0` (two
module paths), `go.opentelemetry.io/otel` → `v1.42.0`, `google.golang.org/grpc`
→ `v1.82.1` — plus a real reliability fix, `fix(ingester): Fix flush race in
ingester [release-3.7.x]` (#23682). This satisfies this ADR's own flip
condition standard ("a new bulletin/fix names a version at or above the
current pin") in the same "ships with a security fix" sense the k3s (RFC #995)
and Vault (2026-08-05 bump) precedents used — not a blind patch assumption.

**Decision: bump `loki:3.7.4` → `3.7.5`** (the newest `3.7.x` patch, smallest
safe delta carrying every fix in the range).
`gitops/observability/loki/deployment.yaml`'s `image:` field updated;
`tests/observability-loki.bats` updated to assert `3.7.5` present and `3.7.4`
absent (recurrence guard, mirrors this repo's other exact-version-pin tests).
Grafana (`13.0.3`) and Tempo (`2.10.5`, confirmed still the newest `2.10.x` tag
via `git ls-remote --tags grafana/tempo` this same run) are unaffected — their
own flip conditions from the prior entries remain unmet.

**ADR-0004 caveat.** This remote, clusterless session verified the commit-range
facts above directly against a real `grafana/loki` clone, but cannot verify
Loki starts cleanly and continues ingesting logs post-bump on a live cluster —
rollback is a one-line revert of the `image:` tag; ArgoCD is not involved here
(Loki is a plain `Deployment`, not an ArgoCD-templated Helm release), so a
revert takes effect on the next manual apply/GitOps sync of `gitops/observability/`;
no data loss either way since Loki's log storage lives in Garage S3, untouched
by an image-tag change.

**Flip condition (next re-evaluation).** Revisit Loki's pin again when a new
advisory/fix range names a version at or above `3.7.5` as affected. Grafana and
Tempo flip conditions remain unchanged from the prior entries above.

### 2026-08-06 — Loki correctness fix found same day, pin bumped `3.7.5` → `3.7.6`

**Trigger.** Planner-fallback currency sweep (`executor.prompt.md` STEP 6b,
Now/next's three standing items still gated on unconfirmed
maintainer-confirmation issues #631/#633) re-checked `grafana/loki`
specifically since it was the freshest bump in this lab's history — the
`3.7.4`→`3.7.5` entry directly above, merged earlier the same day. A new
`v3.7.6` tag had been published in the hours since.

**Verified directly (not assumed, ADR-0004):** `git ls-remote --tags
grafana/loki` / `git log v3.7.5..v3.7.6` on a real clone shows `v3.7.6` as the
newest tag on the `3.7.x` line pinned here (no major/minor jump; nothing newer
released yet). Docker Hub's public tags API confirms the `grafana/loki:3.7.6`
image itself is published (multi-arch manifest, pushed 2026-08-06T09:36 UTC)
— not just a source-repo tag with no matching image. The commit range
contains one substantive fix past a docs backport:
`fix(queryrange): Preserve sketch in MergeLabels [release-3.7.x]` (#23770), a
real query-correctness fix in `pkg/storage/detected/labels.go` (topk/sketch
merging for detected-labels queries returned wrong results without it). No
`[SECURITY]`-tagged commit this time, but a real, verified fix on the exact
patch line this lab tracks meets the same bar the `3.7.4`→`3.7.5` entry's own
non-CVE commit (`fix(ingester): Fix flush race`) used.

**Decision: bump `loki:3.7.5` → `3.7.6`** (the newest `3.7.x` patch, smallest
safe delta carrying the fix above). `gitops/observability/loki/deployment.yaml`'s
`image:` field updated; `tests/observability-loki.bats` updated to assert
`3.7.6` present and `3.7.5` absent (recurrence guard, same pattern as the prior
entry). Grafana and Tempo were not re-checked this cycle (out of scope — this
was a targeted re-check of Loki specifically, not a full stack sweep); their
flip conditions from the prior entries remain unmet as of their last audit.

**ADR-0004 caveat.** Same as the prior entry: this remote, clusterless session
verified the commit-range and published-image facts directly, but cannot
verify Loki starts cleanly and continues ingesting logs post-bump on a live
cluster. Rollback is a one-line revert of the `image:` tag; no data loss
either way since Loki's log storage lives in Garage S3, untouched by an
image-tag change.

**Flip condition (next re-evaluation).** Revisit Loki's pin again when a new
advisory/fix range names a version at or above `3.7.6` as affected.

### 2026-08-06 — Grafana security fix found, pin bumped `13.0.3` → `13.0.5`; Tempo log-drift corrected

**Trigger.** Second planner-fallback currency sweep this run (`executor.prompt.md`
STEP 6b, Now/next's three standing items still gated on unconfirmed
maintainer-confirmation issues #631/#633). A batch `git ls-remote --tags`
check of GitHub-hosted `image:` pins not yet re-checked this run (Mimir,
Grafana's `image.tag` override, RabbitMQ, Valkey) found Grafana's binary pin
one patch behind.

**Verified directly (not assumed, ADR-0004):** `git ls-remote --tags
grafana/grafana` shows `v13.0.5` as the newest tag on the `13.0.x` line (no
minor/major jump — `13.1.x` exists but a version-line jump needs its own
deeper diligence per this ADR's established bar, not bundled into a routine
patch bump). `git log v13.0.3..v13.0.5 --no-merges` (37 commits) contains one
explicitly `Security:`-tagged commit: `[release-13.0.4] Security: Bump
go-pkcs12 to v0.7.2 (GO-2026-5052)`, fixing GHSA-mpwr-8vm7-h73f — a PKCS#12
password-authentication bypass in `software.sslmate.com/src/go-pkcs12`
(affected v0.6.0 up to the fix, pulled in transitively via
`grafana-azure-sdk-go`). This satisfies this ADR's own flip condition
("advisory naming a version at or above the current pin") the same way the
2026-07-19 CVE bump did. `git diff v13.0.3 v13.0.5 -- packaging/docker/` is
**empty** — the Docker image's `run.sh`/`Dockerfile` are byte-identical
across the whole range, so the existing packaging/read-only-root-filesystem
analysis in `observability-grafana.yaml`'s comments carries forward
unchanged, re-verified rather than assumed.

**Decision: bump `grafana:13.0.3` → `13.0.5`** (the newest `13.0.x` patch,
smallest safe delta carrying the fix above).
`gitops/platform/observability-grafana.yaml`'s `valuesObject.image.tag` and
the `ca-bundle` `extraInitContainers` image both updated in lockstep (same
pin, same analysis); `tests/observability-grafana.bats` updated to assert
`13.0.5` present and `13.0.3` absent; `docs/decisions/context.md`'s "Grafana
13.0.3" prose citation updated to `13.0.5` (mechanically enforced by
`make context-doc-version-sync-check`).

**Log-drift correction (Tempo).** While re-checking Tempo's own pin as part
of this same sweep, found it needs no bump — `git ls-remote --tags
grafana/tempo` confirms `2.10.7` (the live pin in
`gitops/observability/tempo/deployment.yaml`) is already the newest `2.10.x`
tag — but this ADR's own last two dated entries (2026-07-28, 2026-08-06)
both still cited the pin as `2.10.5`. That citation lagged an earlier,
undocumented bump; the live pin itself was never wrong. Noting the gap
honestly here rather than silently re-dating the prior entries — same
pattern the 2026-08-06 Loki entry above used for its own `3.7.2`→`3.7.4`
catch-up. No `gitops/` change needed for Tempo.

**ADR-0004 caveat.** This remote, clusterless session verified the
commit-range and packaging-diff facts directly, but cannot verify Grafana
starts cleanly and Git Sync/dashboard provisioning continues working
post-bump on a live cluster. Rollback is a one-line revert of both `image:`
references; Grafana's chart Application syncs via ArgoCD, so a revert takes
effect on the next automated sync; Grafana's session/dashboard state lives on
its PVC, untouched by an image-tag change.

**Flip condition (next re-evaluation).** Revisit Grafana's pin again when a
new advisory names a version at or above `13.0.5` as affected. Tempo's own
flip condition (revisit when a new advisory/fix range names a version at or
above `2.10.7`) is unchanged in substance, only its log citation is now
accurate.

### 2026-08-13 — Tempo security fix found, pin bumped `2.10.7` → `2.10.8`

**Trigger.** Planner-fallback currency sweep (`executor.prompt.md` STEP 6b,
Now/next's six standing items all still gated — three sequential
GitLab→Forgejo migration items need a live-cluster session; the
`verifyImages` Enforce flip, the O4 CI-rejection-gate, and the legacy
capstone `Deployment` removal are all gated on unconfirmed
maintainer-confirmation issues #631/#633, both re-checked this cycle, no new
comment since 2026-08-13 05:57 UTC). A batch `git ls-remote --tags` currency
check across observability-stack components not yet re-checked this run
(Istio, Harbor chart, Grafana/Loki/Mimir/Tempo chart+image lines, KEDA,
Kiali, Trivy Operator, TiDB Operator, External Secrets) found Tempo one
patch behind, satisfying this ADR's own flip condition above.

**Verified directly (not assumed, ADR-0004):** `git ls-remote --tags
grafana/tempo` shows `v2.10.8` as the newest tag on the `2.10.x` line pinned
here (no major/minor jump). A real clone's `git log v2.10.7..v2.10.8`
contains a real security fix, not just routine chores: `chore: update Go to
1.26.5 to fix stdlib CVEs (#7725)` — fixing CVE-2026-39822, CVE-2026-27145,
CVE-2026-42504, CVE-2026-42505, and CVE-2026-42507 in the Go standard
library — plus five further `[security]`-tagged dependency bumps:
`google.golang.org/grpc` → `v1.82.1` (High severity), `golang.org/x/net` →
`v0.56.0`, `golang.org/x/text` → `v0.39.0`, `go.opentelemetry.io/otel` →
`v1.44.0`, and `github.com/klauspost/compress` → `v1.18.7`. Docker Hub's
tags API confirms the `grafana/tempo:2.10.8` multi-arch image is published
(pushed 2026-08-13T17:14 UTC — the same day as this bump). This satisfies
this ADR's own flip condition standard ("advisory/fix range names a version
at or above the current pin") the same "ships with a real fix" way the
2026-08-06 Grafana/Loki entries above used. `git diff v2.10.7 v2.10.8 --
cmd/tempo/Dockerfile packaging/` is **empty** — no packaging/entrypoint
change, so the existing `readOnlyRootFilesystem`/securityContext analysis on
this file's `deployment.yaml` carries forward unchanged.

**Decision: bump `tempo:2.10.7` → `2.10.8`** (the newest `2.10.x` patch,
smallest safe delta carrying every fix above).
`gitops/observability/tempo/deployment.yaml`'s `image:` field updated;
`tests/observability-tempo.bats` updated to assert `2.10.8` present and
`2.10.7` absent (recurrence guard, same pattern as this ADR's Loki entries).
Grafana, Loki, and Mimir were not re-checked this cycle (out of scope — this
was a targeted re-check of Tempo specifically, not a full stack sweep);
their own flip conditions from the prior entries remain unmet as of their
last audit.

**ADR-0004 caveat.** This remote, clusterless session verified the
commit-range and published-image facts directly, but cannot verify Tempo
starts cleanly and continues ingesting/querying traces post-bump on a live
cluster. Rollback is a one-line revert of the `image:` tag; Tempo is a plain
`Deployment`, not an ArgoCD-templated Helm release, so a revert takes effect
on the next manual apply/GitOps sync of `gitops/observability/`; no data
loss either way since Tempo's trace storage lives in Garage S3, untouched by
an image-tag change.

**Flip condition (next re-evaluation).** Revisit Tempo's pin again when a
new advisory/fix range names a version at or above `2.10.8` as affected.
Grafana's own flip condition (revisit when a new advisory names a version at
or above `13.0.5`) is unchanged.

### 2026-08-18 — Grafana routine currency bump, pin bumped `13.0.5` → `13.0.6` (no CVE)

**Trigger.** Executor STEP 6b fallback chain, this run: the three standing
"Now / next" items (GitLab→Forgejo rename/decommission, legacy capstone
`Deployment` removal) all remained gated (the rename item needs a live-cluster
session per its own 2026-08-17 investigation note; the capstone removal is
still gated on unconfirmed issue #633 — re-checked this run, latest comment
2026-08-17 18:50 UTC, still not confirmed) and PLANNER/ARCHITECT fallback
passes found no ungroomed issues, no un-RFC'd 🟡 items, and every CHARTER
Objective (O1–O7) already built/measured. Fell through to UPGRADE-DRAFTER
(`routines/upgrade-drafter.prompt.md`), which walks `gitops/**/*.yaml` for
upgradeable sources — this ADR's own flip condition (`13.0.5`) hadn't
actually fired (no new advisory names `13.0.5`), but the routine's own STEP 2
enumeration/STEP 3 upstream check is unconditional, not flip-condition-gated,
so it re-checked Grafana's pin regardless.

**Verified directly (not assumed, ADR-0004):** GitHub's releases listing for
`grafana/grafana` shows `v13.0.6` (published 2026-08-07) as the newest tag on
the `13.0.x` line — no minor/major jump (the `13.1.x` line exists but a
version-line jump needs its own deeper diligence per this ADR's established
bar, unchanged from the 2026-08-06 entry's reasoning). Docker Hub's tags API
confirms the `grafana/grafana:13.0.6` image is published (pushed
2026-08-07T02:35 UTC). A real diff between the `v13.0.5` and `v13.0.6` tags
(71 changed files, 4 commits) contains **no `Security:`-tagged commit** —
this is a routine patch, not a CVE fix, unlike the two prior entries above.
The four commits: a `BarChart` tooltip fix for a circular-dataframe edge
case, a `SplashScreen` feature-toggle default flip (a toggle this
deployment's `feature_toggles` block never references — only `provisioning`
and `kubernetesDashboards` are set), and a snapshot-deletekey backport (this
lab creates no dashboard snapshots). None of the 71 changed files touch
`packaging/docker/` — the Dockerfile/`run.sh` are byte-identical across the
range, so the existing `readOnlyRootFilesystem`/securityContext analysis in
`observability-grafana.yaml`'s comments carries forward unchanged, re-verified
rather than assumed.

**Decision: bump `grafana:13.0.5` → `13.0.6`** (the newest `13.0.x` patch,
smallest safe delta, honestly not a security-driven bump — a plain currency
catch-up, same category as this repo's other non-CVE chart/image bumps, e.g.
kube-state-metrics `8.3.0`→`8.3.1` the same day).
`gitops/platform/observability-grafana.yaml`'s `valuesObject.image.tag` and
the `ca-bundle` `extraInitContainers` image both updated in lockstep (same
pin, same analysis); `tests/observability-grafana.bats` updated to assert
`13.0.6` present and add a new "no stray `13.0.5`" guard (mirroring the
existing `13.0.1`/`13.0.3` stale-pin guards); `docs/decisions/context.md`'s
"Grafana 13.0.5" prose citation updated to `13.0.6` (mechanically enforced by
`make context-doc-version-sync-check`, which caught the drift live via its
`PostToolUse` hook while authoring this entry).

**ADR-0004 caveat.** This remote, clusterless session verified the
commit-range, changed-file-list, and published-image facts directly, but
cannot verify Grafana starts cleanly and Git Sync/dashboard provisioning
continues working post-bump on a live cluster. Rollback is a one-line revert
of both `image:` references; Grafana's chart Application syncs via ArgoCD, so
a revert takes effect on the next automated sync; Grafana's session/dashboard
state lives on its PVC, untouched by an image-tag change.

**Flip condition (next re-evaluation).** Revisit Grafana's pin again when a
new advisory names a version at or above `13.0.6` as affected, or when the
next scheduled currency sweep finds a newer `13.0.x` patch.

### 2026-08-19 — Grafana security bump, pin bumped `13.0.6` → `13.0.7` (CVE-2026-17183)

**Trigger.** This entry's own flip condition fired: the 2026-08-18 entry's
condition was "revisit when a new advisory names a version at or above
`13.0.6` as affected" — Executor STEP 6b fallback chain (UPGRADE-DRAFTER)
found `v13.0.7` published (GitHub releases, tagged 2026-08-18) citing
`CVE-2026-17183` under a `Security:` heading.

**Verified directly (not assumed, ADR-0004):** GitHub's release notes pages
for `v13.0.7` and the sibling `v13.1.4` release (a different maintained line
— Grafana backports security fixes across every actively-maintained minor
simultaneously) both independently list the identical `Security: CVE-2026-17183`
line plus the identical Enterprise-only reporting bug fix — matching
Grafana's usual coordinated-release-line security-patch shape, not a
one-off. **Honesty caveat:** the CVE detail pages this repo would normally
cross-check for severity/description (`nvd.nist.gov`, `api.osv.dev`,
`grafana.com/security`) were all unreachable from this sandbox's egress
proxy (`EGRESS_BLOCKED`) — a WebSearch aggregation independently estimated
"HIGH" severity but that is not a primary source, so severity here is
reported as "a real, cited CVE fix" without asserting a specific CVSS score
this session couldn't independently confirm. `packaging/docker/run.sh`
diffed byte-identical between the `v13.0.6` and `v13.0.7` tags — no
entrypoint/packaging change, consistent with a pure security patch.

**Decision: bump `grafana:13.0.6` → `13.0.7`** (the newest `13.0.x` patch,
smallest safe delta, security-driven per the release notes).
`gitops/platform/observability-grafana.yaml`'s `valuesObject.image.tag` and
the `ca-bundle` `extraInitContainers` image both updated in lockstep (same
pin, same analysis); `tests/observability-grafana.bats` updated to assert
`13.0.7` present and add a new "no stray `13.0.6`" guard;
`docs/decisions/context.md`'s "Grafana 13.0.6" prose citation updated to
`13.0.7` (mechanically enforced by `make context-doc-version-sync-check`,
which caught the drift live via its `PostToolUse` hook while authoring this
entry, same as the 2026-08-18 entry).

**ADR-0004 caveat.** This remote, clusterless session verified the release
notes and packaging-diff facts directly, but cannot verify Grafana starts
cleanly and Git Sync/dashboard provisioning continues working post-bump on a
live cluster, and could not independently confirm CVE-2026-17183's severity
or technical description beyond the release notes' own citation (egress
proxy blocked every CVE-database domain tried). Rollback is a one-line
revert of both `image:` references; Grafana's chart Application syncs via
ArgoCD, so a revert takes effect on the next automated sync; Grafana's
session/dashboard state lives on its PVC, untouched by an image-tag change.

**Flip condition (next re-evaluation).** Revisit Grafana's pin again when a
new advisory names a version at or above `13.0.7` as affected, or when the
next scheduled currency sweep finds a newer `13.0.x` patch.

### 2026-09-03 — Loki security-relevant bump, pin bumped `3.7.6` → `3.7.7`

**Trigger.** This entry's own flip condition fired: the 2026-08-06 entry's
condition was "revisit when a new advisory/fix range names a version at or
above `3.7.6` as affected" — a planner-fallback currency sweep
(`executor.prompt.md` STEP 6b, Now/next's three standing items still gated
on unconfirmed maintainer-confirmation issues #633/#1229) re-checked
`grafana/loki` as the oldest-reviewed row in `docs/dependency-register.md`
(last reviewed 2026-08-06, the oldest date among all 33 rows as of this
cycle) and found `v3.7.7` published in the interim.

**Verified directly (not assumed, ADR-0004):** GitHub's tags list for
`grafana/loki` shows `v3.7.7` (published 2026-08-27) as the newest tag on
the `3.7.x` line pinned here — no `3.7.8`+ or major/minor jump exists.
`v3.7.7`'s own release notes list three security-relevant dependency
updates (`containerd` module bumped to `v2.2.5`, `etcd` client package
bumped to `v3.6.14`, `golang.org/x/mod` bumped to `v0.40.0`, each cited "for
security purposes") plus a functional change (a flag to ignore missing
chunks during deletion) and a storage optimization (pre-computed SHA-256
hashes to avoid aws-chunked encoding on `PutObject`) — a real, security-
relevant fix set, not a no-op release. Docker Hub's public tag API confirms
`grafana/loki:3.7.7` is published as a real multi-arch manifest (amd64/
arm64/armv7, pushed 2026-08-27T20:15:44Z) — not just a source-repo tag with
no matching image.

**Decision: bump `loki:3.7.6` → `3.7.7`** (the newest `3.7.x` patch, smallest
safe delta carrying the security-relevant dependency bumps above).
`gitops/observability/loki/deployment.yaml`'s `image:` field updated;
`tests/observability-loki.bats` updated to assert `3.7.7` present and
`3.7.6` absent (recurrence guard, same pattern as every prior Loki entry).
Grafana and Tempo were not re-checked this cycle (out of scope — this was a
targeted re-check of Loki specifically, the oldest-reviewed row, not a full
stack sweep); their flip conditions from the prior entries remain unmet as
of their last audit.

**ADR-0004 caveat.** Same as every prior Loki entry: this remote, clusterless
session verified the release-notes and published-image facts directly, but
cannot verify Loki starts cleanly and continues ingesting logs post-bump on
a live cluster. Rollback is a one-line revert of the `image:` tag; no data
loss either way since Loki's log storage lives in Garage S3, untouched by an
image-tag change.

**Flip condition (next re-evaluation).** Revisit Loki's pin again when a new
advisory/fix range names a version at or above `3.7.7` as affected.

### 2026-09-03 — Grafana security bump, pin bumped `13.0.7` → `13.0.8` (3 named CVEs)

**Trigger.** This entry's own flip condition fired: the 2026-08-19 entry's
condition was "revisit when a new advisory names a version at or above `13.0.7`
as affected, or when the next scheduled currency sweep finds a newer `13.0.x`
patch" — a planner-fallback currency sweep (`executor.prompt.md` STEP 6b,
Now/next's three standing items still gated on unconfirmed
maintainer-confirmation issues #633/#1229) found `v13.0.8` published
(GitHub releases, tagged 2026-09-02) citing three `Security:` fixes.

**Verified directly (not assumed, ADR-0004):** GitHub's release notes page for
`v13.0.8` lists, under a `Security` heading: "Fix CVE-2026-12704", "Fix
CVE-2026-14199", "Fix CVE-2026-19475" — three distinct named CVEs, not one
repeated across sibling release lines this time. Docker Hub's public tag API
confirms `grafana/grafana:13.0.8` is a real, published multi-arch manifest
(amd64/arm64/armv7, pushed 2026-09-01T15:21:53Z). Grafana's own CVE-detail
pages (`grafana.com/security/security-advisories/`) remained unreachable from
this sandbox's egress proxy — same limitation as every prior Grafana entry in
this history — so a WebSearch aggregation of third-party CVE trackers
(OffSeq.com) was used instead of a primary source, and is flagged as such
rather than asserted with more confidence than verified: CVE-2026-14199 is
reported HIGH severity, CVSS 7.1 — an Auth Proxy identity-cache key collision
(the cache key concatenates username and forwarded identity attributes with
no delimiter) allowing an authenticated user to authenticate as a
higher-privileged user; this lab's Grafana doesn't use Auth Proxy
authentication (admin credentials come from Vault via ExternalSecret), so not
exploitable here, but the fix ships in the same binary regardless.
CVE-2026-12704 (CWE-294, improper certificate validation) is reported as
Grafana **Enterprise**-specific — this lab runs open-source Grafana, so this
CVE likely doesn't apply, but Enterprise-vs-OSS isn't independently confirmed
beyond the third-party tracker's own component tag. CVE-2026-19475 affects the
PostgreSQL datasource specifically — this lab has no PostgreSQL datasource
configured, so not exploitable here either. No severity/CVSS confirmed for
the latter two beyond the third-party aggregation.

**Decision: bump `grafana:13.0.7` → `13.0.8`** (the newest `13.0.x` patch,
smallest safe delta, security-driven per the release notes — even though none
of the three CVEs are confirmed exploitable in this lab's specific
configuration, patching is still the correct default rather than relying on
a non-exploitability assessment this session can't fully verify against a
primary source). `gitops/platform/observability-grafana.yaml`'s
`valuesObject.image.tag` and the `ca-bundle` `extraInitContainers` image both
updated in lockstep (same pin, same analysis);
`tests/observability-grafana.bats` updated to assert `13.0.8` present and add
a new "no stray `13.0.7`" guard; `docs/decisions/context.md`'s "Grafana
13.0.7" prose citation updated to `13.0.8` (mechanically enforced by `make
context-doc-version-sync-check`, which caught the drift live via its
`PostToolUse` hook while authoring this entry, same as every prior Grafana
bump).

**ADR-0004 caveat.** This remote, clusterless session verified the release
notes and published-image facts directly, but cannot verify Grafana starts
cleanly and Git Sync/dashboard provisioning continues working post-bump on a
live cluster, and could not independently confirm any of the three CVEs'
severity/technical description against a primary source (egress proxy blocked
every CVE-database and grafana.com domain tried) — a WebSearch aggregation
filled the gap for one of the three (CVE-2026-14199) but that is not a
primary source either. Rollback is a one-line revert of both `image:`
references; Grafana's chart Application syncs via ArgoCD, so a revert takes
effect on the next automated sync; Grafana's session/dashboard state lives on
its PVC, untouched by an image-tag change.

**Flip condition (next re-evaluation).** Revisit Grafana's pin again when a
new advisory names a version at or above `13.0.8` as affected, or when the
next scheduled currency sweep finds a newer `13.0.x` patch.

### 2026-09-04 — Tempo currency re-check, no newer image, kept

**Trigger.** Ranked `dependency-register.md` rows by "Last reviewed" date and
picked up the oldest still-untouched entries this run — Tempo's own last
check was 2026-08-13.

**Re-checked directly (ADR-0004):** Docker Hub's tags API confirms neither
`2.10.9` nor `2.11.0` exist for `grafana/tempo` (both 404) — `2.10.8` is still
the newest tag. **Decision: kept.** No currency or security gap. Flip
condition unchanged from the 2026-08-13 entry above.

### 2026-09-06 — Grafana chart bumped `12.10.4` → `12.11.2` (upgrade-drafter fallback)

**Trigger.** Routine currency sweep across `gitops/` chart sources (this
run's executor cycle, `Now / next` fully gated on issues #633/#1229, PLANNER/
ARCHITECT came up empty). `github.com/grafana-community/helm-charts/tags`
shows `grafana-12.11.2` as the newest tag on the `12.x` line — no major bump
(chart stays `12.x`).

**Verified directly (ADR-0004):** Fetched `charts/grafana/templates/_pod.tpl`
at both the `grafana-12.10.4` and `grafana-12.11.2` tags directly from GitHub
and compared the security-relevant blocks: the pod-level `securityContext`
block, the container-level `containerSecurityContext` block, the
`init-chown-data` init container (still gated by
`.Values.initChownData.enabled`, still runs the same `chown -R
{{ .Values.securityContext.runAsUser }}:{{ .Values.securityContext.runAsGroup }}`
command), and the `search` `emptyDir: {}` volume are all unchanged in shape
between the two tags — this ADR's existing `readOnlyRootFilesystem`/PSS-
restricted analysis (recorded further up this file) carries forward
unchanged. The chart's own `Chart.yaml` `appVersion` moved to `13.2.0`
between these tags, but this repo pins the running Grafana image
independently via `valuesObject.image.tag` (currently `13.0.8`, tracked and
audited separately in this ADR's own Re-evaluation log above) — the chart
bump does not change which Grafana binary actually runs, only the chart's
packaging/templates, matching the decoupled chart-version/app-image pattern
this file has used since the RFC #544 chart-source migration
(10.5.15 → 12.7.2).

**Decision: bump `grafana` chart `12.10.4` → `12.11.2`** (the newest `12.x`
tag, no major bump, no CVE — routine packaging currency only).
`gitops/platform/observability-grafana.yaml`'s `spec.source.targetRevision`
updated; `tests/observability-grafana.bats` updated to assert `12.11.2`
present and `12.10.4` absent (recurrence guard, mirrors this repo's other
exact-chart-pin tests). `valuesObject.image.tag` (`13.0.8`) is unaffected by
this change.

**ADR-0004 caveat.** This remote, clusterless session verified the template
facts above directly against the real chart source at both tags, but cannot
verify Grafana starts cleanly and Git Sync/dashboard provisioning continues
working post-bump on a live cluster. Rollback is a one-line revert of
`targetRevision`; ArgoCD reconciles the change on its next sync.

**Flip condition (next re-evaluation).** Revisit when the next scheduled
currency sweep finds a newer `12.x` chart tag, or when Grafana's own image
pin (tracked separately above) needs its next bump.
