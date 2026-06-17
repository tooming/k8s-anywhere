# cosign-bootstrap wiring into `make up` (RFC #214 Item 1, ADR-0019)

**CHARTER Objective O4** (cosign image signing end-to-end).

Wires `scripts/cosign-bootstrap.sh` (merged in `auto/cosign-bootstrap-script`) into
the full `make up` bootstrap sequence per RFC #214 §Decision. The script generates the
cosign keypair and seeds the `cosign-public-key` ConfigMap into the `kyverno` namespace;
inserting it after `garage-bootstrap` ensures the kyverno namespace is already synced by
ArgoCD before the ConfigMap is applied.

## Files changed

| Path | Change |
|------|--------|
| `Makefile` | Added `.PHONY: cosign-bootstrap` target (calls `bash scripts/cosign-bootstrap.sh`); inserted `$(MAKE) cosign-bootstrap` in `make up` after `$(MAKE) garage-bootstrap` |
| `scripts/cosign-bootstrap.sh` | Updated header comment: removed "NOT wired into make up yet", added RFC #214 reference |
| `tests/cosign-bootstrap.bats` | Added `MK` variable to setup; two new assertions: Makefile target exists + `make up` order (cosign-bootstrap follows garage-bootstrap) |

## PR

auto/cosign-make-up-wiring
