# Request And Response Examples

## Intake A Source Record

```http
POST /api/v1/projects/PRJ-AU-00041/source-records
Authorization: Bearer agev_live_demo_7f91
Content-Type: application/json
Idempotency-Key: source-record-demo-1
```

```json
{
  "record_code": "SR-DIT-SDK",
  "source_system": "DIT Evidence API",
  "document_id": "DIT-FEED-2026-07",
  "evidence_type": "feeding_event",
  "evidence_class": "controlled_source",
  "controlled_uri": "evidence://dit-au-methane/source/DIT-FEED-2026-07",
  "commitment": "sha256:4f8c114a02ccf3b9",
  "disclosure_status": "available",
  "status": "received"
}
```

Successful response:

```json
{
  "contract_version": "api-envelope.v1",
  "request_id": "request-id",
  "data": {
    "record_code": "SR-DIT-SDK",
    "project_code": "PRJ-AU-00041",
    "status": "received"
  }
}
```

## Verify An Artifact

```http
POST /api/v1/artifacts/AE-AU-000184/verify
Authorization: Bearer agev_test_demo_2a10
```

Successful response:

```json
{
  "contract_version": "api-envelope.v1",
  "request_id": "request-id",
  "data": {
    "artifact_code": "AE-AU-000184",
    "verifier_result_status": "pending_external_verifier"
  }
}
```

The verifier result is recorded from the configured Rust verifier. If the
verifier binary or trust material is unavailable, Rails records an
indeterminate verifier result instead of performing receipt cryptography.

## Record Reliance

```http
POST /api/v1/artifacts/AE-AU-000184/reliance-events
Authorization: Bearer agev_test_demo_2a10
Content-Type: application/json
```

```json
{
  "relying_party": "Recipient application",
  "relying_party_role": "recipient",
  "reliance_kind": "assurance",
  "status": "recorded"
}
```

Successful response:

```json
{
  "contract_version": "api-envelope.v1",
  "request_id": "request-id",
  "data": {
    "contract_version": "reliance-event.v0",
    "artifact_code": "AE-AU-000184",
    "relying_party": "Recipient application",
    "reliance_kind": "assurance",
    "status": "recorded"
  }
}
```

## Fetch A Contract Schema

```http
GET /api/v1/schemas/artifact-manifest.v0
Authorization: Bearer agev_live_demo_7f91
```

Successful response:

```json
{
  "contract_version": "api-envelope.v1",
  "request_id": "request-id",
  "data": {
    "contract_version": "artifact-manifest.v0"
  }
}
```
