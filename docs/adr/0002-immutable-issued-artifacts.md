# ADR 0002: Immutable Issued Artifacts

## Status

Accepted.

## Decision

Once an artifact is issued, its code, claim, boundary, program, digest, manifest JSON, limitation set, receipt chain, and contract version cannot be silently changed. Corrections create a superseding artifact linked through `supersedes_artifact_id`.

## Consequences

- Issuance updates state fields only.
- Public verification can describe exactly what was issued.
- Reliance events never mutate artifact substance.
- Operational corrections preserve both the original and replacement artifacts.
