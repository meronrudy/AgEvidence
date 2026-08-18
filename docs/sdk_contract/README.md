# AgEvidence SDK Contract

## Contract name
agevidence.v1

## Transport
HTTPS JSON

## Authentication
Bearer API key

## Write idempotency
Idempotency-Key

## API prefix
/v1

## Overview
This document defines the hosted API contract that the AgEvidence Python SDK expects from the AgEvidence Rails application. The Rails application serves as the commercial system of record, exposing a versioned API that the SDK can interact with.

## Architecture
```
External Python SDK
        │
        │ HTTPS / JSON / Bearer API key
        ▼
┌─────────────────────────────┐
│       AgEvidence Rails      │
│                             │
│ /v1/developer/*             │
│ /v1/pricing/*               │
│ /v1/artifact-orders/*       │
│ /v1/country_adapters/*      │
│ /v1/integrations/*          │
│                             │
│ tenancy                     │
│ persistence                 │
│ review                      │
│ evaluation                  │
│ determination               │
│ artifact lifecycle          │
│ billing state               │
│ audit                       │
└──────────────┬──────────────┘
               │
               │ optional private HTTP
               ▼
       Python execution service
       added later/separately
```

## Key Principles

1. **No Python in Rails**: Rails does not install Python, shell out to Python, or import the Python SDK.

2. **No external dependencies**: All schemas, code, and data must be self-contained within the Rails repository.

3. **Tenant isolation**: Account names submitted by clients cannot select tenants; tenant is determined by the API key.

4. **Immutable history**: Historical reviews, determinations, artifacts, and audit events cannot be overwritten.

5. **Append-only review**: Candidate reviews are recorded as append-only history, not mutations.

6. **Separate concerns**: Evidence artifacts, commercial orders, and cryptographic verification remain separate concerns.

## Response Format
All successful responses return the resource object directly, not wrapped in a contract envelope:

```json
{
  "id": "PRJ-123",
  "name": "Methane Trial"
}
```

Every response must include the contract version header:

```
X-AgEvidence-Contract: agevidence.v1
```

## Error Format
All errors return a standardized error object:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Human-readable explanation."
  }
}
```

## Required Scopes
The API uses bearer tokens with scopes for least-privilege access. Required scopes include:

- projects:create
- projects:read
- source_records:create
- source_records:read
- model_runs:create
- model_runs:read
- candidates:read
- candidates:review
- pricing:read
- pricing:create
- artifact_orders:create
- artifact_orders:read
- artifacts:create
- artifacts:read
- country_adapters:read
- country_determinations:create
- country_determinations:read
- integrations:write
- integrations:read
- webhooks:create