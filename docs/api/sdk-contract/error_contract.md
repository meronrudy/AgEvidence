# Error Contract

Current Rails API errors use `error-response.v0` envelopes:

```json
{
  "contract_version": "error-response.v0",
  "request_id": "request-id",
  "error": {
    "code": "validation_failed",
    "message": "Human-readable explanation."
  }
}
```

## Common Codes

| Code | HTTP status | Meaning |
| --- | --- | --- |
| `unauthorized` | 401 | Missing, revoked, or invalid bearer API key. |
| `forbidden` | 403 | API key lacks the required scope or policy access. |
| `not_found` | 404 | The requested project, artifact, record, or schema was not found. |
| `bad_request` | 400 | Request parameters could not be parsed. |
| `validation_failed` | 422 | Request payload failed model validation. |

## Example

```json
{
  "contract_version": "error-response.v0",
  "request_id": "27c5b4e8-1a6d-4b77-b9ad-648018d0a0de",
  "error": {
    "code": "forbidden",
    "message": "The API key is not authorized for this resource."
  }
}
```
