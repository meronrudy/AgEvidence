# AgEvidence

AgEvidence is a monorepo for the AgEvidence protocol, SDKs, research examples,
and Rails console.

## Entry Points

- `protocol/`: canonical schemas, OpenAPI, vocabulary, country adapter packs,
  conformance scripts, and JSON canonicalization rules.
- `docs/api/sdk-contract`: human-readable current `/api/v1` partner contract.
- `packages/python`: Python package published/imported as `agevidence`,
  including local research helpers and legacy client compatibility.
- `packages/rust`: Rust verifier workspace and `agevidence` CLI binary.
- `research/`: reproducible livestock research examples, source manifests,
  notebooks, and tests.
- `apps/console`: Rails console and current `/api/v1` development API.
- `.github/workflows`: Rails and research/package CI.

## Documentation

- [Documentation index](docs/README.md)
- [Current API contract](docs/api/sdk-contract/README.md)
- [Protocol guide](protocol/README.md)
- [Console guide](apps/console/README.md)
- [Python package guide](packages/python/README.md)
- [Researcher guide](docs/researchers/index.md)

## Common Commands

```bash
bash protocol/conformance/scripts/agevidence_check_all.sh
python3 -m pytest packages/python/tests
python3 -m pytest research/tests
python3 research/studies/kebreab/roque-2021/run.py
python3 research/studies/kebreab/methane-database-2024/run.py
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

## Rails Operations

Rails lives in `apps/console` and expects PostgreSQL:

```bash
cd apps/console
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/agevidence_development
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

CI parity commands:

```bash
cd apps/console
bin/rails routes
bin/rails db:prepare
bin/rails db:seed
bin/rails test
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
bundle exec brakeman --no-pager
bundle exec bundle-audit check --update
bundle exec rubocop --fail-level fatal
```

## Public Interfaces

- Current Rails API: `/api/v1`
- Current OpenAPI: `protocol/openapi/agevidence-v1.yaml`
- Legacy source-only OpenAPI:
  `protocol/openapi/legacy/athian-evidence-bazaar/agevidence.v1.yaml`
- Python install/import: `pip install agevidence`, `import agevidence`
- Local research install: `python3 -m pip install -e "packages/python[research,test]"`
- Rust binary: `agevidence verify bundle.json`

Raw workbooks stay outside git under `research/.data/`; local generated research
outputs stay ignored under `research/studies/**/output/`.
