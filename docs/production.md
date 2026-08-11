# Production Runbook

## Runtime

- Ruby 3.4.10
- Rails 8.1.x
- PostgreSQL via `DATABASE_URL`
- Solid Queue for background jobs
- Sprockets assets

## Required Environment

Set `DATABASE_URL`, `RAILS_MASTER_KEY`, `SECRET_KEY_BASE`, and `RAILS_ALLOWED_HOSTS` before booting production. Optional but expected for full operations: SMTP settings and `SENTRY_DSN`.

## Deploy

1. Build the Docker image from `rails_app`.
2. Run the release command: `bin/release`.
3. Start `web` and `worker` processes from `Procfile`.
4. Smoke check `/health`, `/`, `/verify/RA-AU-000184`, and `/app`.

## Demo Access

Seeded development and staging credentials:

- Email: `emma@agevidence.example`
- Password: `correct-horse-battery-staple`

Do not use seeded credentials for a real production organization.
