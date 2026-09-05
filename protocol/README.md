# AgEvidence Protocol

This directory contains the canonical protocol assets shared by Rails, Python,
Rust, and research workflows.

## Contents

- `openapi/agevidence-v1.yaml`: current `/api/v1` OpenAPI contract.
- `openapi/legacy/`: archived source-only contracts kept for migration
  reference.
- `schemas/`: JSON schemas served by the Rails schema endpoint.
- `vocabulary/`: stable global vocabulary families.
- `country_adapters/`: declarative country adapter packs.
- `bundle_profiles/`: artifact bundle profile definitions.
- `trust_policies/`: trust policy placeholders below the Rust verifier
  boundary.
- `conformance/`: local protocol validation scripts and shared fixtures.
- `canonicalization.md`: JSON canonicalization rules.
- `digests.md`: typed digest namespace rules.

## Conformance

Run from the repository root:

```bash
bash protocol/conformance/scripts/agevidence_check_all.sh
```

The conformance suite checks country adapter manifests, vocabulary references,
architecture isolation, canonicalization vectors, adapter behavior, current
OpenAPI paths, and LOC accounting.
