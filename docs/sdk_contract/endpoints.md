# Endpoints

All endpoints are prefixed with `/v1`.

## Developer API

### Projects

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/developer/projects` | Create a project |
| GET | `/v1/developer/projects/:id` | Get a project |

#### POST /v1/developer/projects

**Request:**
```json
{
  "account_name": "Example AgTech",
  "project_name": "Methane Trial",
  "target_claim": "supplier-specific methane reduction evidence",
  "funding_stage": "sandbox",
  "project_type": "intervention",
  "external_project_id": "optional",
  "country_context": {}
}
```

**Response (201):**
```json
{
  "id": "PRJ-123",
  "name": "Methane Trial",
  "developer_account": "Example AgTech",
  "target_claim": "supplier-specific methane reduction evidence",
  "project_type": "intervention",
  "protocol_status": "not_selected",
  "integration_status": "active",
  "evidence_graph_root": null,
  "source_records_url": "/v1/developer/projects/PRJ-123/source_records",
  "model_runs_url": "/v1/developer/projects/PRJ-123/model_runs",
  "artifacts_url": "/v1/developer/projects/PRJ-123/artifacts",
  "authority_boundary": "Evidence is distinct from eligibility, verification, issuance, and claim ownership."
}
```

#### GET /v1/developer/projects/:id

**Response (200):** Same as create response.

### Source Records

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/developer/projects/:project_id/source_records` | Submit a source record |

#### POST /v1/developer/projects/:project_id/source_records

**Request:**
```json
{
  "document_id": "measurement-001",
  "evidence_type": "observation",
  "controlled_uri": "s3://...",
  "commitment": "...",
  "source_system": "python_sdk",
  "evidence_class": "measurement",
  "metadata": {}
}
```

**Response (201):**
```json
{
  "id": "SRC-123",
  "document_id": "measurement-001",
  "evidence_type": "observation",
  "evidence_class": "measurement",
  "source_system": "python_sdk",
  "controlled_uri": "s3://bucket/object",
  "commitment": "abc123...",
  "disclosure_status": "controlled",
  "status": "accepted",
  "operation_id": "OP-123",
  "created_at": "2026-08-18T08:00:00Z"
}
```

### Model Runs

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/developer/projects/:project_id/model_runs` | Create a model run |
| GET | `/v1/developer/model_runs/:id` | Get a model run |

#### POST /v1/developer/projects/:project_id/model_runs

**Request:**
```json
{
  "adapter_id": "qwen3.5-4b-reference"
}
```

**Response (201):**
```json
{
  "id": "RUN-123",
  "project_id": "PRJ-123",
  "adapter_id": "qwen3.5-4b-reference",
  "base_model_id": null,
  "task": "evidence_candidate_extraction",
  "status": "queued",
  "prompt_digest": null,
  "retrieval_digest": null,
  "output_digest": null,
  "limitations": [],
  "candidates": [],
  "gaps": [],
  "completed_at": null
}
```

#### GET /v1/developer/model_runs/:id

**Response (200):** Same as create response.

### Candidates

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/developer/candidates/:id` | Get a candidate |
| PATCH | `/v1/developer/candidates/:id` | Review a candidate |

#### GET /v1/developer/candidates/:id

**Response (200):**
```json
{
  "id": "CAND-123",
  "model_run_id": "RUN-123",
  "candidate_type": "bounded_statement",
  "claim_text": "Recorded methane measurement...",
  "source_references": [],
  "model_confidence": 0.81,
  "review_status": "review_required",
  "review_notes": null,
  "reviewed_by": null,
  "reviewed_at": null,
  "authority_boundary": "Model output is not an institutional determination.",
  "review_decisions": [],
  "latest_decision": null
}
```

#### PATCH /v1/developer/candidates/:id

**Request:**
```json
{
  "decision": "accepted",
  "reason": "Source evidence supports the bounded statement.",
  "reviewer_role": "scientific_reviewer",
  "policy_version": "review-policy.v1"
}
```

**Response (200):** Same as GET response, with updated review state.

### Operations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/developer/operations/:id` | Get an operation |

#### GET /v1/developer/operations/:id

**Response (200):**
```json
{
  "operation_id": "OP-123",
  "status": "running",
  "operation_type": "model_run",
  "started_at": "...",
  "completed_at": null,
  "result": null,
  "error": null
}
```

### Country Determinations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/developer/projects/:project_id/country_determinations` | List determinations |
| POST | `/v1/developer/projects/:project_id/country_determinations` | Create a determination |

#### POST /v1/developer/projects/:project_id/country_determinations

**Request:**
```json
{
  "adapter": "au-accu-livestock-v1",
  "institution_profile": {}
}
```

**Response (201):**
```json
{
  "id": "DET-123",
  "project_id": "PRJ-123",
  "adapter_id": "au-accu-livestock-v1",
  "country_code": "AU",
  "status": "completed",
  "classification": "program_interpretation",
  "authority": "authority",
  "limitations": [],
  "created_at": "2026-08-18T08:00:00Z"
}
```

### Artifacts

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/developer/projects/:project_id/artifacts` | Create an artifact |
| GET | `/v1/developer/projects/:project_id/artifacts/:id` | Get an artifact |
| GET | `/v1/developer/projects/:project_id/artifacts/:id/download` | Download artifact |

#### POST /v1/developer/projects/:project_id/artifacts

**Request:**
```json
{
  "order_id": "ORDER-123",
  "scope": {}
}
```

**Response (201):**
```json
{
  "artifact": {
    "artifact_id": "ART-123",
    "status": "ready",
    "verification_status": "not_verified",
    "receipt_root": null,
    "download_url": "/v1/developer/projects/PRJ-123/artifacts/ART-123/download",
    "verification_command": null,
    "limitations": []
  }
}
```

## Pricing API

### Products

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/pricing/products` | List products |

#### GET /v1/pricing/products

**Response (200):**
```json
{
  "notice": "Pricing is planning guidance until a quote is accepted.",
  "pricing_factors": [],
  "products": [
    {
      "code": "reliance_artifact",
      "name": "Reliance Artifact",
      "billing_type": "one_time",
      "base_planning_price_cents": 2500000,
      "currency": "USD"
    }
  ]
}
```

### Quotes

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/pricing/quotes` | Create a quote |
| GET | `/v1/pricing/quotes/:id` | Get a quote |

#### POST /v1/pricing/quotes

**Request:**
```json
{
  "project_id": "PRJ-123",
  "product_code": "reliance_artifact",
  "scope": {}
}
```

**Response (201):**
```json
{
  "quote_id": "QUOTE-123",
  "product_code": "reliance_artifact",
  "currency": "USD",
  "amount": 2500000,
  "pricing_version": "2026-08",
  "breakdown": [],
  "status": "quoted",
  "expires_at": "...",
  "accepted_at": null,
  "notice": "..."
}
```

## Artifact Orders

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/artifact-orders` | Create an order |
| GET | `/v1/artifact-orders/:id` | Get an order |
| POST | `/v1/artifact-orders/:id/checkout` | Checkout an order |

#### POST /v1/artifact-orders

**Request:**
```json
{
  "quote_id": "QUOTE-123",
  "product_code": "reliance_artifact",
  "scope": {}
}
```

#### POST /v1/artifact-orders/:id/checkout

**Response (200):**
```json
{
  "order_id": "ORDER-123",
  "status": "checkout_completed",
  "checkout_completed_at": "..."
}
```

## Country Adapters

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/country_adapters` | List adapters |
| GET | `/v1/country_adapters/:id` | Get an adapter |
| POST | `/v1/country_adapters/:id/validate` | Validate an adapter |

#### GET /v1/country_adapters

**Response (200):**
```json
{
  "adapters": [
    {
      "adapter_id": "au-accu-livestock-v1",
      "country_code": "AU",
      "version": "1",
      "status": "active",
      "method_id": "method-id",
      "method_version": "2026",
      "authority": "authority",
      "classification": "program_interpretation",
      "limitations": []
    }
  ]
}
```

#### POST /v1/country_adapters/:id/validate

**Response (200):**
```json
{
  "adapter_id": "au-accu-livestock-v1",
  "country_code": "AU",
  "status": "valid",
  "classification": "program_interpretation",
  "errors": [],
  "manifest_path": null
}
```

## Integrations

### Events

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/integrations/events` | Submit an event |
| GET | `/v1/integrations/events/:id` | Get an event |
| POST | `/v1/integrations/events/:id/replay` | Replay an event |

#### POST /v1/integrations/events

**Headers:**
```
X-Athian-Integration-Source: source
X-Athian-Timestamp: timestamp
X-Athian-Signature: signature
Idempotency-Key: key
```

**Response (201):**
```json
{
  "event_id": "EVENT-123",
  "status": "accepted",
  "duplicate": false,
  "operation_id": "OP-456"
}
```

### Webhook Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/integrations/webhook_endpoints` | Create a webhook endpoint |

#### POST /v1/integrations/webhook_endpoints

**Request:**
```json
{
  "url": "https://customer.example/webhooks/agevidence",
  "signing_secret": "secret",
  "subscribed_event_types": [
    "artifact.ready",
    "review.completed"
  ]
}