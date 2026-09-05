# Trust Boundary

AgEvidence separates workflow projections from independently verifiable trust
artifacts.

```text
Rails workflow
  -> SDK/facade ergonomics
  -> Rust verifier kernel
  -> protocol fixtures and trust policies
```

Rails may orchestrate evidence intake, model runs, review, determinations,
artifact issuance, access, and reliance. Rails may compute application digests.
It must not compute receipt commitments, sign receipts, verify receipt
cryptography, evaluate trust policy, or treat database rows as proof.

Integration event signatures are not receipt signatures. Event HMACs establish
that an integration source sent an event. Receipt signatures establish that a
canonical evidence or decision payload was issued under the receipt trust
contract.

The verifier reports separate states:

- cryptographic validity: `pass`, `fail`, `indeterminate`;
- method compatibility: `eligible`, `eligible_with_conditions`,
  `outside_current_method`, `method_extension_required`,
  `insufficient_evidence`, `unassigned`;
- institutional reliance: `accepted`, `relied_on`, `rejected`,
  `needs_more_evidence`.

Do not display one state as a substitute for another.
