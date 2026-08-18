# Error Contract

All errors follow this format:
```json
{
  "error": {
    "code": "<error_code>",
    "message": "<human-readable explanation>",
  }
}
```

## Required Error Codes

| Code | Description | Example Message |
|------|-------------|----------------|
| unauthorized | Invalid or missing API key | "API key not provided or invalid" |
| forbidden | Insufficient permissions | "Missing required scope" |
| not_found | Resource not found | "Project or candidate not found" |
| validation_failed | Input validation error | "Invalid project name format" |
| invalid_request | Malformed request | "Missing required parameters" |
| conflict | Resource conflict | "Duplicate source record" |
| idempotency_conflict | Idempotency key conflict | "Request already processed" |
| runtime_unavailable | Service unavailable | "Model runtime not available" |
| operation_failed | Background operation failed | "Model execution error" |

## Error Response Examples

### 401 Unauthorized
```json
{
  "error": {
    "code": "unauthorized",
    "message": "Invalid API key or missing scope"
  }
}
```

### 403 Forbidden
```json
{
  "error": {
    "code": "forbidden",
    "message": "Missing required scope: projects:create"
  }
}
```

### 404 Not Found
```json
{
  "error": {
    "code": "not_found",
    "message": "Project PRJ-123 not found"
  }
}
```

### 422 Validation Failed
```json
{
  "error": {
    "code": "validation_failed",
    "message": "Project name must be 3-20 characters"
  }
}
```

### 409 Conflict
```json
{
  "error": {
    "code": "idempotency_conflict",
    "message": "Source record already exists with same document ID"
  }
}
```

### 503 Runtime Unavailable
```json
{
  "error": {
    "code": "runtime_unavailable",
    "message": "Model runtime service is down"
  }
}
```

### 500 Operation Failed
```json
{
  "error": {
    "code": "operation_failed",
    "message": "Candidate review failed: insufficient evidence"
  }
}