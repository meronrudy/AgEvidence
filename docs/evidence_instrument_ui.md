# Evidence Instrument UI Kit

This repo keeps a local copy of the shared evidence-instrument UI grammar.

Use the `shared/evidence_instrument/*` partials with plain hashes:

- `label`
- `identifier`
- `status`
- `url`
- `meta`
- `basis_url`

Core components:

- `provenance_rail`: source to evidence to profile to evaluation to determination to artifact.
- `evidence_plate`: document-like object frame for projects, records, artifacts, and determinations.
- `basis_row`: universal consequential-status action with `View basis`.
- `requirement_state`: requirement counts over readiness percentages.
- `profile_stack`: executable program/profile stack.
- `causal_timeline`: event chains with visible cause.
- `verifier_result`: public trust-boundary verification surface.

Styles are namespaced with `.ei-*` so app-specific CSS can evolve without breaking the kit.
