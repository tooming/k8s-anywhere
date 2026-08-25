# docs: log the GitLab CI mirror.gcr.io CGNAT-egress incident

JANITOR-fallback / gap-analysis cleanup, reached via `executor.prompt.md`
STEP 6b — this run's eighth cycle. "Now / next" remains fully gated (issue
#633, unchanged) and PLANNER/ARCHITECT/UPGRADE-DRAFTER/DOC-DRIFT-AUTHOR/
TRIAGER were re-confirmed unchanged from cycles 3–4. **No prerequisites —
executor may pick up immediately.**

## The gap

Continuing this run's sweep of issue #631/#633's real, undocumented
incidents (after Cilium, Vault, several NetworkPolicy/credential bugs, and
three probe-timeout incidents already logged across cycles 1–7): the
2026-08-13 comment on issue #631 also mentioned a distinct GitLab CI fix —
`docker.io` base-image pulls failing across 4 consecutive pipeline runs with
`i/o timeout`, fixed by adding a `mirror.gcr.io` registry mirror. Never had
its own row. The fix's actual date (per its own inline comment in
`.gitlab-ci.yml`, the authoritative source) is 2026-08-12, one day earlier
than the issue comment describing it.

## What was checked before logging it

Verified the fix is still live: `.gitlab-ci.yml`'s `docker:29.7.2-dind`
service still carries `--registry-mirror=https://mirror.gcr.io`, with a
detailed inline comment matching (and slightly extending, with the CGNAT
`100.64.0.0/10` IP-range detail) what the issue comment described. Used the
file's own comment as the primary source over the issue comment where they
overlap, since it's the more authoritative, closer-to-the-fix record.

## The fix

Added one row (2026-08-12, **P2** — a CI-pipeline reliability issue, not an
always-on-component degradation), placed chronologically between the
existing 2026-08-11 Kyverno row and 2026-08-13 harbor-registry OOMKill row.
Cites the exact CGNAT IP range, the 4 failed pipeline runs, and the
successful pipeline #63 that confirmed the fix. No mechanical guard added —
this is a live host-networking transient, the same class already
(uncredited) referenced by the existing 2026-08-17 `argo-rollouts` row.
Added a matching bats assertion.

`make ci`: green (full local run including real `bats`).

## PR

<!-- filled in after opening the PR -->
