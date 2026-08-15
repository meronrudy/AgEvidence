# ADR 0001: Standalone Rails With Protocol Boundary

## Status

Accepted.

## Decision

Build AgEvidence as a standalone production Rails application. Rails owns the commercial workflow and data model. Companion repositories provide protocol knowledge only until a real external integration is required.

## Consequences

- Rails models and services remain the system of record for commercial evidence work.
- `/api/v1`, artifact manifests, verifier results, webhook envelopes, and error responses are explicit versioned contracts.
- SDKs and independent verifier runtimes stay outside this repository and integrate through documented contracts.
