# Build a Methane Evidence Startup

## The Business

Provide neutral evidence infrastructure for feed additives, devices, livestock methane programs, and project developers.

## Who Pays

Feed and additive companies, MRV project developers, processors, retailers, and assurance firms.

## The Incumbent Workflow Being Unbundled

Vertically integrated MRV stacks combine customer acquisition, data capture, methodology, calculation, verification workflow, registry, and buyer relationship. This recipe attacks the evidence and verification layers.

## What Information Enters Your Product

Animal cohorts, product lots, feeding events, methane measurements, lab records, model runs, calibration support, and reviewer decisions.

## AgEvidence Primitives

Use `SourceRecord` for custody, `InterventionEvent` for treatment, `OperationalEvent` for feeding and farm operations, `Observation` for measurement evidence, and `ModelRun` for modeled methane outcomes.

## Rails Screens To Keep

Keep projects, source records, evidence, gaps, assessment, review, determinations, artifacts, verification, reliance, ProgramProfiles, developer keys, OpenAPI, logs, and webhooks.

## Rails Screens To Delete

Delete only screens that do not support your buyer workflow. In the first pass, keep the whole reference app and rename it around methane evidence.

## What You Rename

Rename projects to evidence cases, gaps to readiness checks, determinations to methane evidence statements, and artifacts to reliance packages if that fits your market.

## What You Build Yourself

Build connectors for feed systems, measurement devices, lab systems, herd management tools, and buyer reporting systems. Add domain-specific model adapters only above the shared evidence layer.

## First API Integration

Accept intervention and observation events from a feed additive customer or methane measurement device.

## First Evidence Artifact

Issue a qualified methane intervention evidence statement bounded to supplied source records and model runs.

## First External Verifier

Start with artifact digest and manifest reconstruction, then integrate an independent verifier when available.

## Proprietary Moat

Distribution to methane technology vendors, access to measurement networks, methodology expertise, device integrations, and buyer relationships.

## Keep Interoperable

Source records, observations, intervention events, model runs, artifacts, verification results, and reliance events.
