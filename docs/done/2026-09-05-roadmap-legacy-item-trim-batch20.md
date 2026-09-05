# ROADMAP.md legacy `[x]` item trim — batch 20

Continuing the pilot batch, batch 2 through batch 19
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch5.md](2026-09-04-roadmap-legacy-item-trim-batch5.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch6.md](2026-09-04-roadmap-legacy-item-trim-batch6.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch7.md](2026-09-05-roadmap-legacy-item-trim-batch7.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch8.md](2026-09-05-roadmap-legacy-item-trim-batch8.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch9.md](2026-09-05-roadmap-legacy-item-trim-batch9.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch10.md](2026-09-05-roadmap-legacy-item-trim-batch10.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch11.md](2026-09-05-roadmap-legacy-item-trim-batch11.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch12.md](2026-09-05-roadmap-legacy-item-trim-batch12.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch13.md](2026-09-05-roadmap-legacy-item-trim-batch13.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch14.md](2026-09-05-roadmap-legacy-item-trim-batch14.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch15.md](2026-09-05-roadmap-legacy-item-trim-batch15.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch16.md](2026-09-05-roadmap-legacy-item-trim-batch16.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch17.md](2026-09-05-roadmap-legacy-item-trim-batch17.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch18.md](2026-09-05-roadmap-legacy-item-trim-batch18.md),
[docs/done/2026-09-05-roadmap-legacy-item-trim-batch19.md](2026-09-05-roadmap-legacy-item-trim-batch19.md)).

## What was done

Found and trimmed 5 more large fully-inline `[x]` items (all "no pointer yet"
cases this batch — two of them (`artifactory`/`longhorn-system`/`istio-system`
PSA+NP items and their Kiali follow-up) date back to the repo's original
`k8s-lab` name, so their `docs/done/` mirror files cite `pull/NNN` under the
old `tooming/k8s-lab` URL — each was independently re-verified as `merged:
true` against the *current* `tooming/k8s-anywhere` repo, same PR number,
before trimming), each re-verified against its real `docs/done/` mirror and a
confirmed-`merged: true` PR before touching the ROADMAP text:

- **Gateway HTTPS listener + wildcard Certificate + frontdoor `:8443` port
  mapping** →
  [docs/done/2026-07-16-cert-manager-gateway-https.md](2026-07-16-cert-manager-gateway-https.md)
  (PR #440)
- **verifyImages ClusterPolicy — Audit → Enforce flip** →
  [docs/done/2026-08-18-cosign-enforce-flip.md](2026-08-18-cosign-enforce-flip.md)
  (PR #1223)
- **PSA `baseline` labels + NetworkPolicy — `artifactory` namespace** →
  [docs/done/2026-06-29-auto-pss-np-artifactory.md](2026-06-29-auto-pss-np-artifactory.md)
  (PR #298)
- **PSS `privileged` labels + NetworkPolicy — `longhorn-system`** →
  [docs/done/2026-06-27-pss-np-longhorn.md](2026-06-27-pss-np-longhorn.md)
  (PR #284)
- **NetworkPolicy extensions — Kiali allows in `istio-system`** →
  [docs/done/2026-06-29-kiali-np-istio-system.md](2026-06-29-kiali-np-istio-system.md)
  (PR #299)

No information lost — the full detail already lives in each linked
`docs/done/` file, confirmed equivalent by reading all five before editing.

## Why this is in scope for a JANITOR cycle

Same fallback-chain walk as batches 7-19, re-confirmed fresh this cycle: the
two remaining "Now / next" gates (issues #633 and #1229) were re-checked
directly via the GitHub API — neither has a new confirmation comment; no
other open PRs exist. JANITOR continues the established legacy-item-trim
cleanup using the same targeted `awk` scan introduced in batch 16, this time
also widening the mirror search beyond a title-substring `ls` grep to a full
content grep across `docs/done/*.md` for a few candidates whose filename
didn't obviously match their ROADMAP title.

## Result

`ROADMAP.md`: 3916 → 3784 lines (132 lines saved from 5 items). `make ci`
passes green (lint, README/lab-UI/roadmap drift checks, ADR chart/image-pin
sync, dependency-register sync, every `docs/done/` file's PR-link check all
clean; `bats`/`kustomize`/`terraform` aren't installed in this remote
clusterless session, so those steps no-op locally as usual — the real
backstop is GitHub Actions' `ci.yml`).

No `gitops/` change.

## PR

(filled in after PR creation)
