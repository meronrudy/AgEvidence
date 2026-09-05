# Current API Endpoints

All active Rails partner endpoints are prefixed with `/api/v1`.

## Evidence

| Method | Path | Scope | Description |
| --- | --- | --- | --- |
| `POST` | `/api/v1/evidence` | `evidence:create` | Intake an evidence payload. |
| `GET` | `/api/v1/evidence/{id}` | `evidence:read` | Retrieve an evidence record by record code. |

## Source Records

| Method | Path | Scope | Description |
| --- | --- | --- | --- |
| `POST` | `/api/v1/projects/{project_code}/source-records` | `source_records:create` | Intake a source record for a project. |
| `GET` | `/api/v1/projects/{project_code}/source-records/{record_code}` | `source_records:read` | Retrieve a public-safe source record summary. |

## Evaluations, Reviews, And Profiles

| Method | Path | Scope | Description |
| --- | --- | --- | --- |
| `GET` | `/api/v1/evaluations` | `evaluations:read` | List project evaluations visible to the API key. |
| `GET` | `/api/v1/evaluations/{id}` | `evaluations:read` | Retrieve an evaluation by code. |
| `GET` | `/api/v1/reviews` | `reviews:read` | List review state visible to the API key. |
| `GET` | `/api/v1/program_profiles` | `program_profiles:read` | List program profiles. |
| `GET` | `/api/v1/program_profiles/{id}` | `program_profiles:read` | Retrieve a program profile by code or slug. |

## Statements And Artifacts

| Method | Path | Scope | Description |
| --- | --- | --- | --- |
| `GET` | `/api/v1/statements` | `statements:read` | List statements. |
| `GET` | `/api/v1/statements/{id}` | `statements:read` | Retrieve a statement by artifact code. |
| `POST` | `/api/v1/statements/{id}/shares` | `statements:share` | Create a statement share. |
| `GET` | `/api/v1/artifacts/{artifact_code}` | `artifacts:read` | Retrieve a public-safe artifact summary. |
| `POST` | `/api/v1/artifacts/{artifact_code}/verify` | `artifacts:verify` | Record an AgEvidence verifier result. |
| `POST` | `/api/v1/artifacts/{artifact_code}/reliance-events` | `reliance_events:create` | Record reliance on an artifact. |

## Contract Schemas

| Method | Path | Scope | Description |
| --- | --- | --- | --- |
| `GET` | `/api/v1/schemas/{contract_version}` | `schemas:read` | Retrieve a checked-in JSON contract schema. |

Supported `contract_version` values:

- `artifact-manifest.v0`
- `verifier-result.v0`
- `verifier-report.v1`
- `webhook-envelope.v0`
- `error-response.v0`

## Legacy Contract

The historical `/v1/developer`, `/v1/pricing`, `/v1/artifact-orders`,
`/v1/country_adapters`, and `/v1/integrations` routes are not active Rails
routes in this monorepo. Their source-only OpenAPI document remains archived at
`protocol/openapi/legacy/athian-evidence-bazaar/agevidence.v1.yaml` for SDK
compatibility and migration reference.
