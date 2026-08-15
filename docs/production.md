# Production Runbook

## Runtime

- Ruby 3.4.10
- Rails 8.1.x
- PostgreSQL through `DATABASE_URL`
- Solid Queue worker from `Procfile`
- Sprockets assets
- Docker build context: this `rails_app` directory

## Required Environment

Set these before booting production:

- `DATABASE_URL`
- `RAILS_MASTER_KEY`
- `SECRET_KEY_BASE`
- `RAILS_ALLOWED_HOSTS`

Expected for commercial operations:

- SMTP settings
- `SENTRY_DSN`
- object storage settings when file intake is enabled

## Build And Release

From `rails_app`:

```sh
docker build -t agevidence-rails:COMMIT_SHA .
docker run --rm \
  -e RAILS_ENV=production \
  -e DATABASE_URL="$DATABASE_URL" \
  -e RAILS_MASTER_KEY="$RAILS_MASTER_KEY" \
  -e SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  -e RAILS_ALLOWED_HOSTS="$RAILS_ALLOWED_HOSTS" \
  agevidence-rails:COMMIT_SHA \
  bin/release
```

`bin/release` runs:

```sh
bundle exec rails db:prepare
```

Start processes from `Procfile`:

```sh
web: bundle exec puma -C config/puma.rb
worker: bundle exec rails solid_queue:start
```

## Smoke Checks

- `GET /health`
- `GET /verify`
- `GET /verify/:artifact_code` for a known public-safe artifact
- authenticated `GET /app`
- enqueue and perform one background job probe
- confirm Sentry receives an event when `SENTRY_DSN` is configured

Production and staging hostnames are not documented until DNS and deployment targets are verified.

## Seed Safety

Run `bin/rails db:seed` only in development or staging demo environments. Production customer data must be created through migrations, admin workflows, imports, or audited support procedures.

## Rollback

- Keep the previous image tag available.
- Capture database backup metadata before migration.
- Prefer forward fixes for migrated commercial records.
- If rollback is required, restore both the previous application image and a compatible database state.

## Public Verification

Public verification exposes only artifact code, status, digest, claim, boundary, program/profile version, limitation summary, issue timestamp, and AgEvidence verifier placeholder status. It must not expose restricted source metadata, organization internals, audit metadata, or third-party verification claims.
