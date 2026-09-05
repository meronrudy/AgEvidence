# Canonicalization Conformance

Each vector directory contains:

- `input.json`: source JSON;
- `expected.json`: exact RFC 8785/JCS UTF-8 output for positive vectors;
- `expected.sha256`: SHA-256 over `expected.json` bytes without a trailing
  newline;
- `metadata.yaml`: vector metadata.

Vectors with `expected_error` in metadata MUST be rejected by conforming
implementations.
