# Build Government Program Infrastructure

## The Business

Encode agricultural program requirements once and evaluate many suppliers, projects, or applicants against them.

## Who Pays

Government agencies, program administrators, registries, public-private partnerships, and regulated buyers.

## The Incumbent Workflow Being Unbundled

Program systems are often built as bespoke portals by systems integrators. This recipe treats program rules as versioned configuration over shared evidence primitives.

## What Information Enters Your Product

Applications, source records, observations, interventions, operational events, model outputs, reviewer decisions, determinations, appeals, and reliance records.

## AgEvidence Primitives

Use `ProgramProfile` for the program, `Requirement` for machine and human-review checks, `Evaluation` for requirement execution, `Determination` for published outcomes, and `Artifact` for portable program outputs.

## Rails Screens To Keep

Keep ProgramProfiles, requirements, versions, evaluate, compare, evaluations, determinations, source records, review, artifacts, verification, schemas, OpenAPI, and logs.

## Rails Screens To Delete

Delete market-specific commercial workflow only after the program workflow is implemented.

## What You Rename

Rename projects to applications or cases, ProgramProfiles to program versions, gaps to missing requirements, and artifacts to program determinations.

## What You Build Yourself

Build applicant intake, jurisdiction-specific rules, appeals, reporting, case assignment, public transparency views, and data-sharing agreements.

## First API Integration

Accept source records and observations from one external applicant or supplier system.

## First Evidence Artifact

Issue a program determination bounded to one profile version and evidence set.

## First External Verifier

Let an applicant, buyer, or auditor verify a determination outside the program portal.

## Proprietary Moat

Jurisdiction knowledge, procurement access, program design, integrations, and public-sector delivery.

## Keep Interoperable

Requirements, evaluations, determinations, artifacts, verification results, and reliance events.
