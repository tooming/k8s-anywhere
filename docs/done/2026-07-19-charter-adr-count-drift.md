# CHARTER.md — stop hardcoding the ADR count

(CLAUDE.md §"Every bugfix must prevent recurrence" — janitor fallback role, invoked
via `executor.prompt.md` STEP 6b, same CHARTER-gap read-through that found the
KEDA stale-follow-up note earlier this run — PR #571.)

CHARTER.md's "Strategy" section opened with "The 26 ADRs in `docs/decisions/` are
the binding receipts" — stale: `docs/decisions/` holds 30 ADR files as of this run
(`adr-0001` through `adr-0030`, several added earlier today). Verified directly
(ADR-0004) via `ls docs/decisions/adr-*.md | wc -l`.

Fixed by removing the literal count rather than updating it to "30" — a hardcoded
number in prose has no mechanism forcing anyone to keep it current (the exact same
root cause as the ADR-0006 stale follow-up note and the KEDA CHARTER note fixed
earlier this run), so it would just go stale again at ADR-0031. The sentence reads
correctly without the count: "The ADRs in `docs/decisions/` are the binding
receipts."

No dedicated mechanical guard added — a hardcoded count in free-form prose is a
narrower, one-off case than the two prior drift classes this run already guarded
(unchecked ADR/CHARTER "follow-up" promises), and removing the count is itself the
recurrence-proof fix (nothing left to drift).

Behavior-preserving: pure prose correction. `make ci` passes.

## PR

(filled in after PR creation)
