# AgEvidence Console

AgEvidence Console is the reference implementation of an evidence-native
agriculture company. It is the commercial Rails application for evidence
intake, normalization, evaluation, determination, artifact issuance, access,
verification status, and reliance records.

In the monorepo it lives under `apps/console`. The canonical protocol, SDKs,
fixtures, and verifier live at repository root outside this Rails app.

Use it as a working product surface that founders can inspect, clone, strip
down, specialize, and commercialize. The seeded demo shows a DIT Production
Evidence project moving through source records, normalized evidence, gaps,
evaluation, human review, determination, immutable artifact issuance,
verification status, and reliance.

## Reference Business Flow

```text
source records
  -> normalized evidence
  -> evaluations and gaps
  -> human review
  -> determinations
  -> immutable artifacts
  -> verification and reliance
```

Keep the evidence identities, provenance, evaluation lifecycle, determination
lifecycle, artifact structure, verification contract, and reliance records.
Configure ProgramProfiles, requirements, evidence vocabulary, jurisdiction, and
buyer workflow. Replace vertical integrations, pricing, brand, proprietary
analytics, and domain-specific models.

## Local Setup

Required:

- Ruby 3.4.10
- PostgreSQL 13 or newer
- Bundler

Set an explicit PostgreSQL URL, including user and host, then prepare the app. Do not rely on an implicit local operating-system role.

```sh
cd apps/console
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
cd apps/console
export RAILS_ENV=test
export DATABASE_URL=postgres://postgres:postgres@localhost:5432/agevidence_test
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:seed
bin/rails test
```

CI also runs:

```sh
cd apps/console
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile
bundle exec brakeman --no-pager
bundle exec bundle-audit check --update
bundle exec rubocop --fail-level fatal
```

## Production

The Rails app deploys from `apps/console` using `Dockerfile`, `Procfile`, and
`bin/release`. Required production settings are documented in
`apps/console/docs/production.md`.

Production and staging URLs are intentionally not listed until DNS and deploy targets are verified.

## Commercial Boundary

- Source records describe custody and identity of supplied material.
- Evidence records are normalized projections used by the workflow.
- Evaluations apply a versioned program profile to accepted evidence.
- Determinations are bounded statements AgEvidence is prepared to publish.
- Artifacts are immutable issued reliance packages.
- Verifier results are delegated to the Rust verifier; unavailable trust material is recorded as indeterminate.
- Reliance events are distinct from artifact issuance and access grants.
