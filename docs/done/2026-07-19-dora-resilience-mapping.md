# `docs/dora-resilience-mapping.md` — DORA (EU regulation) pillar mapping, explicitly not a compliance claim

(RFC #586 — architect decision 2026-07-19.) Implements RFC #586's binding spec:
this lab is not an EU-regulated "financial entity" or a designated critical ICT
third-party provider under Regulation (EU) 2022/2554 Article 2, so it must never
claim DORA regulatory compliance anywhere in the repo.

New `docs/dora-resilience-mapping.md` opens with an explicit, prominent
applicability disclaimer naming DORA's real Article 2 scope and this lab's
non-membership in it, then maps four of the five pillars onto real,
already-existing repo mechanisms:

1. **ICT risk management framework** → the ADR process +
   CLAUDE.md's bugfix-recurrence-guard discipline, citing ADR-0016
   (default-deny NetworkPolicy), ADR-0017 (PSS-restricted), ADR-0022 (Trivy
   continuous scanning).
2. **ICT incident management/classification/reporting** → `docs/dora-metrics.md`'s
   real "Time to restore service" row (RFC #580 / Objective O7,
   `make dora-metrics`), cited directly rather than re-derived.
3. **Digital operational resilience testing** → `make dr-verify`, `make dr-test`,
   `make dr-bluegreen` as real, exercised recovery drills (see `docs/DR.md`).
4. **ICT third-party risk management** → Trivy Operator continuous scanning
   (ADR-0022), `scripts/helm-chart-pin-check.sh`, ADR-0025's free/OSS-tier
   policy.
5. **Information-sharing arrangements** → explicit "not applicable" note (this
   pillar concerns inter-financial-entity threat-intel consortiums; nothing in
   a solo personal lab maps to it honestly).

The CHARTER Goals-section sentence was already present (landed in RFC #586's own
architect PR, #587) — verified before starting, not re-added.

Every citation was verified to actually exist before committing: `ls
docs/decisions/adr-0016-*` through `-0025-*`, the three `dr-*` Makefile targets,
`scripts/helm-chart-pin-check.sh`, and `docs/DR.md` all confirmed present.
`make ci`'s markdown-link check passes on the new file's relative links.

`make ci` passes. Closes #586.

## PR

https://github.com/tooming/k8s-anywhere/pull/589
