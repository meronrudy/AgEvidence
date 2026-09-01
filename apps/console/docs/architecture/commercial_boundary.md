# Commercial Boundary

AgEvidence Rails is the commercial system of record for evidence work and reliance. It owns projects, source records, normalized evidence, model run records, gaps, reviews, evaluations, determinations, artifacts, access grants, verifier-result records, and reliance events.

## Protocol Reference

The companion `athian-evidence-bazaar` repository is read-only reference material for:

- vocabulary and object shapes
- JSON schema and OpenAPI patterns
- synthetic fixtures and negative cases
- interface conformance expectations
- future verifier and SDK integration requirements

Protocol concepts are adopted at Rails service/API boundaries only when a real integration needs them.

## Non-goals

- Do not embed the Tenacious Python SDK in this Rails app.
- Do not embed Rust verifier crates or release automation.
- Do not copy local-first client assumptions into commercial workflows.
- Do not put country-specific behavior in generic models or controllers; keep it in profile data and services.
- Do not produce unversioned public payloads, webhooks, verifier results, or artifact manifests.
- Do not claim independent cryptographic verification until an external verifier exists.

## Invariants

- Tenant-owned records are scoped through `organization_id` directly or through project ownership.
- Controllers use `policy_scope` before lookup for commercial records.
- Human judgment is recoverable through append-only review or disposition rows.
- Issued artifact substance is immutable; corrections supersede.
- Reliance is separate from issuance and access.
- Consequential transitions write `AuditEvent` rows.
