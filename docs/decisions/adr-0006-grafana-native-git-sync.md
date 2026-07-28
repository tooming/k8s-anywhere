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
