# AgEvidence

AgEvidence is a monorepo for the AgEvidence protocol, SDKs, research examples,
and Rails console.

## Entry Points

- `protocol/`: canonical schemas, OpenAPI, vocabulary, conformance scripts, and
  JSON canonicalization rules.
- `packages/python`: Python SDK and CLI package published/imported as
  `agevidence`.
- `packages/rust`: Rust verifier workspace and `agevidence` CLI binary.
- `research/`: reproducible livestock research examples and tests.
- `apps/console`: Rails console and `/api/v1` development API.
- `.github/workflows`: CI for Rails and research/package checks.

## Common Commands

```bash
bash protocol/conformance/scripts/agevidence_check_all.sh
python3 -m pytest packages/python/tests
python3 -m pytest research/tests
cd packages/rust && cargo test
cd apps/console && bin/rails test
```

For local researcher workflows, install the SDK from the repository root:

```bash
python3 -m pip install -e "packages/python[research,test]"
```

The canonical OpenAPI document is
`protocol/openapi/agevidence-v1.yaml`; the active Rails API server path is
`/api/v1`. Legacy source-only imports remain archived under
`protocol/openapi/legacy/`.
