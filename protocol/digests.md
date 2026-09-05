# AgEvidence Digest Namespaces

AgEvidence digests are typed. A digest without its domain prefix is not a
receipt, bundle, schema, or policy commitment.

## Format

```text
<domain>:sha256:<lowercase-hex-sha256>
```

Allowed v1 domains:

```text
app
event
receipt
bundle
schema
policy
```

## Domains

- `app:sha256:<digest>` identifies Rails or SDK application-level stable data.
- `event:sha256:<digest>` identifies integration-event payload bytes.
- `receipt:sha256:<digest>` identifies a receipt commitment computed by the
  Rust verifier kernel.
- `bundle:sha256:<digest>` identifies a bundle commitment computed by the Rust
  verifier kernel.
- `schema:sha256:<digest>` identifies a protocol schema commitment.
- `policy:sha256:<digest>` identifies a trust-policy commitment.

Legacy untyped `sha256:<digest>` values may appear in historical records,
external source commitments, and compatibility fixtures. New trust-sensitive
protocol material MUST use the typed form.
