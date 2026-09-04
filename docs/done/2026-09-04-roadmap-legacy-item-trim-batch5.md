# ROADMAP.md legacy `[x]` item trim — batch 5

Continuing the pilot batch, batch 2, batch 3, and batch 4
([docs/done/2026-09-04-roadmap-legacy-item-trim-pilot.md](2026-09-04-roadmap-legacy-item-trim-pilot.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch2.md](2026-09-04-roadmap-legacy-item-trim-batch2.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch3.md](2026-09-04-roadmap-legacy-item-trim-batch3.md),
[docs/done/2026-09-04-roadmap-legacy-item-trim-batch4.md](2026-09-04-roadmap-legacy-item-trim-batch4.md)).

## What was done

Trimmed 5 more legacy items — the O2/O4/O5 cloud-control-plane dashboard,
PSS/NetworkPolicy fan-out, and cosign CI-signing sequence — each verified
against its real `docs/done/` mirror before touching the ROADMAP text:

- Lab — Cloud control-plane (moto / ACK / KRO) dashboard →
  [docs/done/2026-06-13-cloud-control-plane-dashboard.md](2026-06-13-cloud-control-plane-dashboard.md)
  (PR #201)
- PSS-restricted fan-out — `moto` + `ack-system` + `lab-gateway` →
  [docs/done/2026-06-14-pss-moto-ack-labgateway.md](2026-06-14-pss-moto-ack-labgateway.md)
  (PR #202)
- NetworkPolicy fan-out — `tidb` + `tidb-admin` →
  [docs/done/2026-06-14-networkpolicy-tidb-fanout.md](2026-06-14-networkpolicy-tidb-fanout.md)
  (PR #203)
- cosign-bootstrap wiring into `make up` →
  [docs/done/2026-06-17-cosign-make-up-wiring.md](2026-06-17-cosign-make-up-wiring.md)
  (PR #222 — this mirror already had a real link)
- `cosign sign` stage in `.gitlab-ci.yml` →
  [docs/done/2026-06-17-cosign-ci-sign-step.md](2026-06-17-cosign-ci-sign-step.md)
  (PR #223)

As with batches 3-4, four of these five `docs/done/` mirrors had no `## PR`
section at all (only one, the cosign-make-up-wiring mirror, already
carried a real link). Found each real merged PR via GitHub search
(#201, #202, #203, #223, all confirmed `merged: true`) and added a proper
`## PR` section to each mirror before pointing ROADMAP.md at it
(ADR-0004 — never propagate an unverifiable/missing PR reference into the
trimmed form).

Each item's full inline text replaced with the established short-pointer
format. No information lost — the full detail already lived in the linked
`docs/done/` files (now each with a real PR link), confirmed equivalent
by reading all five before editing.

## Result

`ROADMAP.md`: 7055 → 6944 lines (111 lines saved from 5 items). ~157
legacy items remain for future bounded cycles to continue against.

No `gitops/` change. `make ci` passes green.

## PR

https://github.com/tooming/k8s-anywhere/pull/1414
