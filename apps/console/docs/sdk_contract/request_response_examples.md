# Request/Response Examples

## Project Creation

### Request
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

### Response (201)
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

## Source Record Submission

### Request
```json
{
  "document_id": "measurement-001",
  "evidence_type": "observation",
  "controlled_uri": "s3://bucket/object",
  "commitment": "abc123...",
  "source_system": "python_sdk",
  "evidence_class": "measurement",
  "metadata": {}
}
```

### Response (201)
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

## Model Run Creation

### Request
```json
{
  "adapter_id": "qwen3.5-4b-reference"
}
```

### Response (201)
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

## Candidate Review

### Request
```json
{
  "decision": "accepted",
  "reason": "Source evidence supports the bounded statement.",
  "reviewer_role": "scientific_reviewer",
  "policy_version": "review-policy.v1"
}
```

### Response (200)
```json
{
  "id": "CAND-123",
  "model_run_id": "RUN-123",
  "candidate_type": "bounded_statement",
  "claim_text": "Recorded methane measurement...",
  "source_references": [],
  "model_confidence": 0.81,
  "review_status": "accepted",
  "review_notes": "Source evidence supports the bounded statement.",
  "reviewed_by": "scientific_reviewer",
  "reviewed_at": "2026-08-18T08:05:00Z",
  "authority_boundary": "Model output is not an institutional determination."
}
```

## Country Determination

### Request
```json
{
  "adapter": "au-accu-livestock-v1",
  "institution_profile": {}
}
```

### Response (201)
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

## Pricing Quote

### Request
```json
{
  "project_id": "PRJ-123",
  "product_code": "reliance_artifact",
  "scope": {}
}
```

### Response (201)
```json
{
  "quote_id": "QUOTE-123",
  "product_code": "reliance_artifact",
  "currency": "USD",
  "amount": 2500000,
  "pricing_version": "2026-08",
  "breakdown": [],
  "status": "quoted",
  "expires_at": "2026-09-18T08:00:00Z",
  "accepted_at": null,
  "notice": "Pricing is planning guidance until a quote is accepted."
}
```

## Artifact Order

### Request
```json
{
  "quote_id": "QUOTE-123",
  "product_code": "reliance_artifact",
  "scope": {}
}
```

### Response (200)
```json
{
  "order_id": "ORDER-123",
  "status": "checkout_completed",
  "checkout_completed_at": "2026-08-18T08:05:00Z"
}
```

## Integration Event

### Request
```json
{
  "source": "python_sdk",
  "event_type": "artifact.ready",
  "payload": {
    "artifact_id": "ART-123",
    "project_id": "PRJ-123"
  }
}
```

### Response (201)
```json
{
  "event_id": "EVENT-123",
  "status": "accepted",
  "duplicate": false,
  "operation_id": "OP-456"
}