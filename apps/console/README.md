# AgEvidence Rails

AgEvidence is a standalone commercial Rails application for evidence intake, normalization, evaluation, determination, artifact issuance, access, verification status, and reliance records. It is the commercial system of record. It does not embed the Tenacious Python SDK or a Rust verifier.

The companion `athian-evidence-bazaar` repository is read-only protocol reference material for vocabulary, schema shape, fixtures, negative cases, and future conformance expectations.

## Local Setup

Required:

- Ruby 3.4.10
- PostgreSQL 13 or newer
- Bundler

Set an explicit PostgreSQL URL, including user and host, then prepare the app. Do not rely on an implicit local operating-system role.

```sh
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/agevidence_development
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Demo sign-in after seeding:

- Email: `demo`
- Password: `demo`

## Test And CI Commands

Use PostgreSQL for test parity:

```sh
export RAILS_ENV=test
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/agevidence_test
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:seed
bin/rails test
```

CI also runs:

```sh
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
bundle exec brakeman --no-pager
bundle exec bundle-audit check --update
bundle exec rubocop --fail-level fatal
```

## Production

The Rails app deploys from this `rails_app` directory using `Dockerfile`, `Procfile`, and `bin/release`. Required production settings are documented in `docs/production.md`.

Production and staging URLs are intentionally not listed until DNS and deploy targets are verified.

## Commercial Boundary

- Source records describe custody and identity of supplied material.
- Evidence records are normalized projections used by the workflow.
- Evaluations apply a versioned program profile to accepted evidence.
- Determinations are bounded statements AgEvidence is prepared to publish.
- Artifacts are immutable issued reliance packages.
- Verifier results are currently AgEvidence placeholders, not independent cryptographic verification.
- Reliance events are distinct from artifact issuance and access grants.
