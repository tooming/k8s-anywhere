# Bump Trivy Operator chart `0.35.0` → `0.36.0` (bundled scanner `0.73.0` → `0.74.0`)

(CHARTER **Core Values** §"Everything as code" + general dependency hygiene; upgrade-drafter fallback, executor.prompt.md STEP 6b — this run's eighth cycle: the "Now / next" lane remained fully gated (two GitLab→Forgejo migration items + the capstone-`Deployment`-removal item, all blocked on unconfirmed live-cluster prerequisites — issues #633/#1229/#1345, unchanged since 2026-08-25), PLANNER found no ungroomed intake or un-RFC'd 🟡 item. This cycle's own currency sweep re-checked KEDA (confirmed current, `v2.20.2` still newest) and Trivy Operator, since neither had been re-fetched cold in this run's own earlier digest.)

Verified directly (not assumed, ADR-0004) via the real Atom feed (`github.com/aquasecurity/helm-charts/releases.atom`, ISO-8601 `<updated>` `2026-08-24T12:37:49Z`): `trivy-operator-0.36.0` is one release past this lab's pinned `0.35.0`. The `aquasecurity/helm-charts` git repo's `main` branch carries no chart source (chart-releaser publishes packaged `.tgz` assets + a `gh-pages` Helm repo index instead — raw source and index.yaml fetches both failed in this sandbox), so verification followed this ADR's own established method: downloaded both `trivy-operator-0.35.0.tgz` and `trivy-operator-0.36.0.tgz` release assets directly and ran `diff -ru` on the extracted trees.

**Findings.** Exactly three kinds of change, matching the shape of every prior bump in this ADR's Re-evaluation log: `Chart.yaml`'s `version`/`appVersion` (`0.35.0`→`0.36.0`, appVersion `0.33.0`→`0.34.0`), `README.md` badges/table, and the bundled `trivy.image.tag` default (`0.73.0`→`0.74.0`, in both `values.yaml` and `README.md`), plus the same version-label bump repeated across five `templates/specs/*.yaml` compliance-scan CronJob manifests (label only, not behavior). No other `values.yaml` key changed shape — every key this lab's `valuesObject` sets (`operator.*`, `trivy.resources`/`storageClassName`/`storageSize`, `nodeCollector.*`) is present and unchanged.

`git log v0.33.0..v0.34.0` (trivy-operator app repo) shows 4 commits: 2 routine dependency bumps and the Trivy scanner version bump itself (`chore: bump up Trivy version to 0.74.0`) plus a release-prep commit — no operator-side feature/fix commit. The bundled Trivy scanner bump (`v0.73.0`→`v0.74.0`) does carry real fixes per its own `CHANGELOG.md` (fetched directly): Java scanning metadata-section fix, Terraform misconfiguration parsing fixes (Azure parameter parsing, `for_each` unknown-value panic prevention, OpenTofu language-block support), and Python `pyproject.toml` dependency-name normalization — real detection-accuracy/stability fixes, no CVE.

**This Application is ALWAYS-ON** (automated sync) — this pin takes effect on the next ArgoCD reconciliation.

Bumped `gitops/platform/trivy-operator.yaml`'s `targetRevision: 0.35.0` → `0.36.0`. Appended a new dated entry to [ADR-0022](../decisions/adr-0022-trivy-operator-supply-chain.md)'s Re-evaluation log. Updated `tests/trivy-operator.bats`'s pin assertions (retitled, negative assertion extended to include the superseded `0.35.0`) and `docs/dependency-tree.md`/`docs/dependency-register.md`'s citations.

**ADR-0004 caveat.** This remote clusterless session cannot verify the Trivy Operator/scanner pods actually restart cleanly on the new chart version on a live cluster, or that scan jobs continue to run successfully. Since this is always-on/auto-synced, that verification should happen promptly after this merges. Rollback path: revert `targetRevision` back to `0.35.0`.

## PR

(filled in after PR creation)
