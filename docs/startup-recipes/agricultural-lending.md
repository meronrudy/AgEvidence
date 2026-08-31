# Build an Agricultural Lending Evidence Startup

## The Business

Turn heterogeneous farm telemetry and operational records into lender-ready evidence packages.

## Who Pays

Agricultural lenders, embedded finance providers, farm software platforms, and borrowers who need faster underwriting.

## The Incumbent Workflow Being Unbundled

Lenders often depend on manual document collection, proprietary farm portals, and one-off underwriting requests. This recipe makes evidence portable across farm systems.

## What Information Enters Your Product

Farm management records, production history, inventory, weather and risk observations, practice adoption records, machinery operations, insurance documents, and third-party attestations.

## AgEvidence Primitives

Use `SourceRecord` for document custody, `Observation` for farm state and performance evidence, `OperationalEvent` for management activity, `ModelRun` for underwriting models, `Determination` for bounded credit-readiness outcomes, and `RelianceEvent` when a lender uses an artifact.

## Rails Screens To Keep

Keep projects, source records, evidence, gaps, evaluations, determinations, artifacts, verification, reliance, developer keys, schemas, OpenAPI, and webhooks.

## Rails Screens To Delete

Remove methane-specific program pages only after replacing them with lending ProgramProfiles.

## What You Rename

Rename ProgramProfiles to underwriting profiles, gaps to underwriting conditions, artifacts to lender evidence packages, and reliance events to lender reliance records.

## What You Build Yourself

Build connectors to farm software, accounting tools, lender portals, document stores, and risk data providers.

## First API Integration

Submit source records and operational observations from one farm management system.

## First Evidence Artifact

Issue a lender evidence package for a single borrower and production season.

## First External Verifier

Let a lender verify artifact integrity and source-record commitments without logging into your admin app.

## Proprietary Moat

Lender distribution, underwriting interpretation, farm-system integrations, risk models, and borrower onboarding.

## Keep Interoperable

Artifact manifests, source records, observations, verification results, and reliance events.
