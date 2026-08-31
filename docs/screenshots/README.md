# Screenshot Suite

The screenshot suite is documentation for founders and a visual regression check for the seeded reference app.

Run from the repository root:

```sh
bin/screenshots
```

The command resets the development database, loads the canonical seed data, starts Rails if needed, signs in as the demo user, visits the manifest routes, and writes images into this directory.

Demo login:

- Email: `demo`
- Password: `demo`

## Manifest

| File | Route | Founder lesson |
| --- | --- | --- |
| `00-overview.png` | `/app` | Evidence is a product surface, not backend plumbing. |
| `01-project.png` | `/app/projects/dit-production` | Organize work around a commercial evidence case. |
| `02-source-records.png` | `/app/projects/dit-production/source_records` | Preserve provenance and custody. |
| `03-evidence.png` | `/app/projects/dit-production/evidence` | Turn device and software outputs into reusable evidence. |
| `04-gaps.png` | `/app/projects/dit-production/gaps` | Sell evidence readiness, not just data storage. |
| `05-assessment.png` | `/app/projects/dit-production/assessment` | Execute rules over accepted evidence. |
| `06-review.png` | `/app/projects/dit-production/review` | Keep human judgment explicit. |
| `07-artifact.png` | `/app/projects/dit-production/artifact` | Issue something portable. |
| `08-reliance.png` | `/app/projects/dit-production/reliance` | Record downstream use. |
| `09-verification.png` | `/verify/AE-AU-000184` | Let recipients verify without app access. |
| `10-program-profile.png` | `/app/programs/profiles` | Encode a market as versioned configuration. |
| `11-developer.png` | `/app/developer` | Expose the evidence layer to developers. |
| `12-webhooks.png` | `/app/developer/webhooks` | Integrate into existing agtech workflows. |
| `13-openapi.png` | `/app/developer/openapi` | Give partners stable contracts. |
