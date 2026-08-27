# AgEvidence API Contract

## Contract

- Canonical OpenAPI: `protocol/openapi/agevidence-v1.yaml`
- Server prefix: `/api/v1`
- Transport: HTTPS JSON
- Authentication: bearer API key
- Idempotency header for mutating requests: `Idempotency-Key`
- JSON schemas served by Rails from: `protocol/schemas`

The active Rails console API is the `/api/v1` partner surface for source
intake, artifact access, placeholder verification results, reliance events, and
checked-in contract schemas.

The older source-only `/v1` Developer OS contract is preserved as an archive at
`protocol/openapi/legacy/athian-evidence-bazaar/agevidence.v1.yaml`. Do not use
that archived contract as the source of truth for new Rails routes.

## Response Envelopes

Successful current API responses use a versioned envelope:

```json
{
  "contract_version": "api-envelope.v1",
  "request_id": "request-id",
  "data": {}
}
```

Errors use `error-response.v0`:

```json
{
  "contract_version": "error-response.v0",
  "request_id": "request-id",
  "error": {
    "code": "unauthorized",
    "message": "A valid API key is required."
  }
}
```

## Active Resources

- `POST /api/v1/evidence`
- `GET /api/v1/evidence/{id}`
- `POST /api/v1/projects/{project_code}/source-records`
- `GET /api/v1/projects/{project_code}/source-records/{record_code}`
- `GET /api/v1/evaluations`
- `GET /api/v1/evaluations/{id}`
- `GET /api/v1/reviews`
- `GET /api/v1/program_profiles`
- `GET /api/v1/program_profiles/{id}`
- `GET /api/v1/statements`
- `GET /api/v1/statements/{id}`
- `POST /api/v1/statements/{id}/shares`
- `GET /api/v1/artifacts/{artifact_code}`
- `POST /api/v1/artifacts/{artifact_code}/verify`
- `POST /api/v1/artifacts/{artifact_code}/reliance-events`
- `GET /api/v1/schemas/{contract_version}`

## Required Scopes

API keys are digest-backed and scoped. Seeded demo keys include the scopes used
by Rails tests:

- `evidence:create`
- `evidence:read`
- `evaluations:read`
- `reviews:read`
- `program_profiles:read`
- `statements:read`
- `statements:share`
- `source_records:create`
- `source_records:read`
- `artifacts:read`
- `artifacts:verify`
- `reliance_events:create`
- `schemas:read`

## Boundaries

Rails does not import or shell out to the Python SDK. The Python package owns
local research helpers and legacy client compatibility. The Rust workspace owns
canonical JSON, hashing, bundle, and verifier primitives.
