# Security Threat Model

## Surfaces

- Tenant isolation across HTML, API, downloads, jobs, webhooks, and audit export.
- Artifact access and public verification.
- API keys and webhook signing secrets.
- Source references and future object storage URLs.
- Audit records and administrator actions.

## Controls

- Use `policy_scope` before commercial record lookup.
- Store API tokens as SHA-256 digests; never return raw tokens after issue.
- Redact credentials and protected payload fields from API logs.
- Keep source files in private object storage when file intake is added; persist references and digests only.
- Use short-lived signed URLs for protected downloads.
- Keep audit tombstones when deletion/redaction is legally required.
- Use organization-scoped feature flags for unfinished commercial surfaces and integrations.

## Drills

- Disable a compromised API key.
- Replay a failed webhook after signature validation.
- Rotate a webhook signing key.
- Restore a backup into a clean environment and compare artifact checksums.
- Produce an organization-scoped audit export.
