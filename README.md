# AgEvidence

Open evidence infrastructure for building agriculture companies.

AgEvidence shows what an evidence-native agtech company can become, then gives founders a path to specialize that evidence layer into their own market. The Rails console is the complete reference business: projects, source records, normalized evidence, gaps, evaluations, review, determinations, artifacts, downloadable bundles, reliance, verification, ProgramProfiles, API keys, schemas, OpenAPI, logs, and webhooks.

Rails shows the company. `pip install agevidence` gives you the primitives. The repository teaches you how to specialize those primitives into a company.

Hero screenshot: [docs/screenshots/00-overview.png](docs/screenshots/00-overview.png)

## See -> Run -> Embed -> Fork -> Sell

### See It

Inspect a complete evidence workspace in `apps/console`. It is seeded with a DIT Production Evidence project, an Australian methane intervention ProgramProfile, source records, SDK-produced evidence, intervention and operational events, measurement evidence, model runs, gaps, evaluation, review, determination, issued artifact, verification result, reliance event, API key, schemas, OpenAPI, logs, webhooks, and integrations.

### Run It

```sh
git clone https://github.com/meronrudy/AgEvidence
cd AgEvidence
bin/demo
```

Then open `http://127.0.0.1:3000`.

If port 3000 is already in use, `bin/demo` selects the next open port and prints the URL.

Demo login:

- Email: `demo`
- Password: `demo`

### Embed It

You liked what you saw in Rails. Now put the evidence layer inside your product.

```sh
pip install agevidence
```

```python
from agevidence import Client

client = Client(base_url="http://localhost:3000", api_token="agev_test_demo_2a10")

project = client.create_project(
    account_name="Northstar Methane Systems Sandbox",
    project_name="Enterprise dairy pilot",
    target_claim="The intervention reduces enteric methane.",
)

source = client.submit_source_record(
    project_id=project.id,
    document_id="feeding-event-001",
    evidence_type="agevidence.intervention_event.v1",
    controlled_uri="evidence://feeding-event-001",
    commitment="sha256:demo",
)
```

Your product generated something valuable. Make it attributable, bounded, versioned, portable, reviewable, and independently reconstructable.

### Fork It

Choose a startup. Keep the evidence layer. Specialize the market.

| Startup archetype | Initial buyer | Keep from AgEvidence | Specialize |
| --- | --- | --- | --- |
| Methane evidence API | Feed, additive, and device companies | Observations, interventions, model runs, artifacts | Livestock schemas and methods |
| Input efficacy evidence network | Biological and input companies | Source records, trial observations, determinations | Field-trial workflows |
| Agricultural lending evidence | Lenders | Artifacts, verification, reliance | Underwriting ProgramProfiles |
| Agricultural insurance evidence | Insurers | Source records, events, verification | Loss and peril evidence |
| Scope 3 and insetting evidence | Processors and retailers | Programs, evaluations, artifacts | Buyer requirements |
| Independent MRV | Project developers | Evidence, review, determinations | Methodology modules |
| Assurance operating system | Auditors and assurance providers | Review, gaps, artifacts | Reviewer workflows |
| Agronomy claims verification | Agronomy and input startups | Observations, models, provenance | Agronomic models |
| Farm-data portability layer | Farm software companies | Schemas, source records, bundles | Connectors |
| Agricultural AI evidence firewall | Buyers of AI recommendations | Model runs, source records, evaluations | Model lineage and benchmarks |
| Regulatory program engine | Government and program administrators | ProgramProfiles, requirements, evaluations | Jurisdiction modules |
| Evidence marketplace | Buyers and agtech suppliers | Artifacts, verification, reliance | Discovery and commerce |

### Sell It

AgEvidence is strongest when many vertical companies share one evidence grammar. A methane company, lending company, assurance firm, input-efficacy network, model verifier, and data-portability layer can all have different brands, customers, workflows, models, and pricing while producing compatible source records, observations, intervention events, operational events, model runs, artifacts, verification results, and reliance events.

## From Telemetry To Reliance

```text
YOUR AGTECH PRODUCT
  observations / interventions / models / operations
        |
        v
+----------------------------+
| agevidence                 |
| SourceRecord               |
| Observation                |
| InterventionEvent          |
| OperationalEvent           |
| ModelRun                   |
+-------------+--------------+
              |
              v
       Evidence Workspace
              |
       +------+------+
       v             v
  Evaluation       Gaps
       |             |
       +------+------+
              v
            Review
              |
              v
        Determination
              |
              v
       Issued Artifact
              |
      +-------+-------+
      v       v       v
    Buyer   Auditor  Bank
              |
              v
       Reliance Event
```

You do not need to rebuild this because your startup happens to sell feed additives, pasture intelligence, robotics, methane measurement, farm software, crop models, biological inputs, agricultural finance, or assurance.

## Product Tour

The seeded Rails app is designed to produce a deterministic screenshot suite. Regenerate it with:

```sh
bin/screenshots
```

| Screenshot | Route | What you are looking at | What you could turn it into |
| --- | --- | --- | --- |
| `00-overview.png` | `/app` | Evidence command center | Any evidence SaaS |
| `01-project.png` | `/app/projects/dit-production` | One commercial evidence case | Enterprise workflow |
| `02-source-records.png` | `/app/projects/dit-production/source_records` | Provenance and custody | Traceability infrastructure |
| `03-evidence.png` | `/app/projects/dit-production/evidence` | Normalized product telemetry | IoT or MRV infrastructure |
| `04-gaps.png` | `/app/projects/dit-production/gaps` | Evidence readiness gaps | Compliance/readiness startup |
| `05-assessment.png` | `/app/projects/dit-production/assessment` | Machine evaluation | Regulatory automation |
| `06-review.png` | `/app/projects/dit-production/review` | Human-in-the-loop assurance | Assurance platform |
| `07-artifact.png` | `/app/projects/dit-production/artifact` | Portable issued statement | Evidence exchange |
| `08-reliance.png` | `/app/projects/dit-production/reliance` | Downstream use of evidence | Bank, buyer, or insurer workflow |
| `09-verification.png` | `/verify/AE-AU-000184` | Verification without app access | Verification API |
| `10-program-profile.png` | `/app/programs/profiles` | Market rules as configuration | Compliance startup |
| `11-developer.png` | `/app/developer` | Developer platform surface | API company |
| `12-webhooks.png` | `/app/developer/webhooks` | Integration delivery | Embedded infrastructure |
| `13-openapi.png` | `/app/developer/openapi` | Stable contracts | Ecosystem platform |

Each screenshot should be documented as: what you are looking at, why it matters, and what a founder could turn it into.

## ProgramProfiles Are The Verticalization Layer

AgEvidence primitives plus a ProgramProfile plus vertical UX becomes a new evidence company.

Examples:

- `AU Methane Intervention Profile` -> Dairy lending underwriting profile
- `AU Methane Intervention Profile` -> Biological input efficacy profile
- `AU Methane Intervention Profile` -> Processor Scope 3 supplier profile
- `AU Methane Intervention Profile` -> Crop insurance loss evidence profile

Use ProgramProfiles to encode requirements, evidence classes, evaluation modes, version impacts, limitation templates, and artifact policy. Keep the evidence identities, artifact structure, verification contract, and reliance records interoperable.

## What To Keep, Configure, And Replace

Founders should not need to understand every file before the clone stops looking like AgEvidence.

Start here:

- [docs/START-HERE.md](docs/START-HERE.md)
- [docs/STARTUP_MAP.md](docs/STARTUP_MAP.md)
- [docs/startup-recipes/README.md](docs/startup-recipes/README.md)
- [apps/console/README.md](apps/console/README.md)

Short version:

| Layer | Reuse unchanged | Configure | Replace |
| --- | --- | --- | --- |
| Canonical evidence primitives | yes | no | no |
| Verification contracts | yes | no | no |
| Bundle format | yes | no | no |
| Provenance rules | yes | no | no |
| Organization model | yes | no | no |
| API authentication | yes | no | no |
| ProgramProfiles | no | yes | no |
| Requirements | no | yes | no |
| Evidence vocabulary | no | yes | no |
| UI terminology | no | yes | no |
| Buyer workflow | no | yes | no |
| Vertical integrations | no | no | yes |
| Pricing | no | no | yes |
| Customer-facing brand | no | no | yes |
| Proprietary analytics | no | no | yes |
| Domain-specific models | no | no | yes |

## Developer Commands

Run these from the repository root:

```sh
bin/doctor       # check Ruby, Bundler, PostgreSQL, Rails boot, and demo seed
bin/demo         # prepare and start the seeded Rails reference app
bin/reset-demo   # reset development DB and reload deterministic seeds
bin/test         # run the Rails test suite
bin/screenshots  # capture docs screenshots from the seeded app
```

The scripts delegate into `apps/console` and default to:

```sh
DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/agevidence_development
```

## Repository Components

| Component | Founder mental model |
| --- | --- |
| `protocol/` | The shared language |
| `packages/python/` | Put evidence inside your product |
| `packages/rust/` | Trust something without trusting a SaaS |
| `apps/console/` | See a complete evidence company working |
| `research/` | Prove that the system can reconstruct real science |
| `docs/startup-recipes/` | Turn it into your company |

## Deeper Documentation

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

## Public Interfaces

- Current Rails API: `/api/v1`
- Current OpenAPI: `protocol/openapi/agevidence-v1.yaml`
- Legacy source-only OpenAPI: `protocol/openapi/legacy/athian-evidence-bazaar/agevidence.v1.yaml`
- Python install/import: `pip install agevidence`, `import agevidence`
- Local research install: `python3 -m pip install -e "packages/python[research,test]"`
- Rust binary: `agevidence verify bundle.json`

Raw workbooks stay outside git under `research/.data/`; local generated research outputs stay ignored under `research/studies/**/output/`.

Current Rails verifier results are AgEvidence placeholder records, not independent cryptographic verification. Do not claim independent verification until an external verifier exists.
