# Release Checklist

- Confirm migrations are reversible where practical and include required indexes/foreign keys.
- Run `bin/rails db:prepare`, `bin/rails db:migrate`, `bin/rails db:seed`, and `bin/rails test` against PostgreSQL.
- Confirm seeds are idempotent and safe for the target environment.
- Run production asset build with `SECRET_KEY_BASE_DUMMY=1`.
- Run Brakeman, bundle-audit, and RuboCop.
- Smoke check `/health`, `/verify`, a known public artifact lookup, and authenticated `/app`.
- Confirm a background job can be enqueued and executed by the worker.
- Confirm Sentry receives a test event when `SENTRY_DSN` is configured.
- Capture database backup metadata before deploy.
- Confirm rollback image/tag and database rollback or forward-fix plan.
