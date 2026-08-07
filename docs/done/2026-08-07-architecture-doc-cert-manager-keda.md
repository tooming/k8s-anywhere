# docs/00-architecture.md — add cert-manager and KEDA (missing from the primary learning-path doc)

Executor filler item (ROADMAP rule #9, "doc precision"; executor.prompt.md STEP 6b
fallback chain — cycle 10, after the Now/next lane remained gated on #631/#633/#1034
and prior fresh-lens sweeps this run found nothing further). `docs/00-architecture.md`
is CHARTER's own named pointer for "the sequenced path" a learner should walk (CHARTER
Goals section: "The sequenced path lives in docs/00-architecture.md"), and CHARTER's
own "Target end-state" section explicitly lists both **cert-manager** ("TLS
certificate lifecycle... works identically on localhost and the Oracle backend") and
**KEDA** ("Event-driven autoscaling... Engine is auto-synced, restricted PSA with zero
carve-out") as already-**built** always-on core components.

**Verified directly (ADR-0004):** grepped `docs/00-architecture.md` for
"cert-manager"/"KEDA"/"keda" before making any change — zero matches. Both components
are real, live, always-on ArgoCD Applications (`gitops/platform/cert-manager.yaml`,
`gitops/platform/keda.yaml`), each with its own binding ADR (ADR-0028, ADR-0029), yet
neither appeared anywhere in the doc's layer diagram, "Who does what" tables, or the
12-step "Suggested learning path" — a real gap in the platform's primary onboarding
reference, not a cosmetic wording issue.

**Fix:** added both to the "Always-on in-cluster workloads" ASCII diagram (new `TLS`
and `AUTOSCALE` rows); added a new "### TLS / certificates" subsection (cert-manager,
after Ingress) and a new "### Autoscaling" subsection (KEDA, after Data layer) to the
"Who does what" tables; extended the existing learning-path steps 2 (Core platform)
and 4 (Data layer) with a sentence each, rather than inserting new numbered steps —
avoids renumbering the doc's own step-6/step-11 self-references and any other file
that might cite a specific step number.

No mechanical guard added — this is a one-off content gap in a hand-written narrative
doc (unlike README.md's stack table or the Lab UIs panel, `docs/00-architecture.md`
has no drift-detectable source of truth to diff against: it's prose describing
*why*, not a generated inventory). Noted here rather than silently assumed covered.

`make ci` passes.

## PR

https://github.com/tooming/k8s-anywhere/pull/1069
