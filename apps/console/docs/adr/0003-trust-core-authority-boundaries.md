# ADR 0003: Trust-Core Authority Boundaries

## Status

Accepted.

## Context

AgEvidence now keeps protocol contracts, SDKs, the Rust verifier, and the Rails
console in one forward monorepo. The legacy `athian-evidence-bazaar`
implementation remains useful as migration and architectural reference, but it
is not a second source of trust semantics.

## Decision

`protocol/` is the normative protocol authority for schemas, vocabulary, bundle
profiles, trust policies, canonicalization rules, OpenAPI, and conformance
fixtures.

The Rust verifier kernel is the normative implementation for canonical byte
generation, cryptographic hashing, receipt verification, signature
verification, bundle integrity, trust-policy evaluation, and offline verifier
CLI behavior.

Rails owns workflow, persistence, access, application digests, API/webhook
authentication, artifact presentation, verifier-result records, and reliance
records. Rails must not define receipt commitments, sign receipts, verify
receipt signatures, compute bundle commitments, or decide cryptographic
validity independently of the Rust verifier.

Python and Ruby SDKs own developer ergonomics, HTTP access, integration-event
helpers, and local verifier delegation. They must not implement authoritative
receipt cryptography in v1.

## Terminology

- `application_digest`: application-level stable hash such as
  `app:sha256:<digest>`.
- `event_signature`: integration authentication signature, usually HMAC over
  a normalized event envelope.
- `receipt_commitment`: `receipt:sha256:<digest>` produced from receipt signing
  bytes by the Rust verifier kernel.
- `bundle_commitment`: `bundle:sha256:<digest>` produced from trust-relevant
  bundle contents by the Rust verifier kernel.
- `cryptographic_validity`: parse, canonicalization, digest, signature, and
  bundle-integrity status.
- `method_compatibility`: country or program method interpretation over valid
  evidence.
- `institutional_reliance`: a relying party's recorded decision to accept,
  rely on, reject, or request more evidence.

## Consequences

- `protocol/canonicalization.md` is the byte-level authority.
- `agevidence verify <bundle> --json` is the integration contract for Rails,
  Ruby, and Python.
- The current verifier should be described as a portable verification kernel or
  assurance-targeted verifier until independent reconstruction milestones are
  complete.
- Integration HMACs and receipt signatures remain separate concepts.
