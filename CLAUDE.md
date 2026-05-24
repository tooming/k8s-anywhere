# k8s-lab — working agreement

## Architecture decisions are binding
Before proposing OR implementing any technical/tooling choice, consult
`docs/decisions/` (the ADRs). They are binding, not advisory.

- **Never** implement something that contradicts an ADR. If you think an ADR should
  be revisited, **STOP and ask first** — name the ADR, explain why you'd deviate, and
  let the user decide. Do not act against an ADR unprompted, even partially or in a
  proposal/plan.
- ADRs named `adr-NNNN-<chosen>-not-<rejected>.md` encode a **rejected** option — treat
  it as off-limits (e.g. ADR-0002: Garage, NOT MinIO).
- A `SessionStart` hook (`scripts/adr-context-hook.sh`) surfaces every ADR's decision at
  the start of each session — read it. A `PostToolUse` guard (`scripts/adr-guard-hook.sh`)
  flags edits to infra/code that reintroduce a rejected technology.
- ADR-0004: never fabricate content as real state; **verify before asserting** that
  something is deployed/working.

## Always open a PR
After pushing changes to the feature branch, **always open a pull request** for them
(unless the user says otherwise). Don't wait to be asked.
