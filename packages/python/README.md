# AgEvidence Python SDK and CLI

This is the canonical Python package for the AgEvidence Developer OS.

It wraps the Rails `/v1` API for projects, source records, model runs,
candidate review, quotes, artifact orders, artifacts, integration events,
webhooks, and operations. Receipt issuance and cryptographic verification stay
behind `ink_receipts` and the Rust trust boundary.

Sandbox pricing and orders are illustrative planning records. They are not
booked, collected, or recognized revenue.

## Install

From the repository root:

```bash
python3 -m pip install -e "sdks/python[test]"
```

Check the CLI:

```bash
agevidence --help
agevidence replay project-4030 --help
```

## Configure

```bash
agevidence login --base-url http://localhost:3000
```

Configuration is loaded from explicit client arguments, environment variables,
or `~/.config/agevidence/config.json`.

Environment variables:

```text
AGEVIDENCE_BASE_URL
AGEVIDENCE_API_TOKEN
AGEVIDENCE_INTEGRATION_SOURCE
AGEVIDENCE_INTEGRATION_SECRET
AGEVIDENCE_VERIFIER_COMMAND
```

`AGEVIDENCE_API_TOKEN` is sent as a bearer token when configured.

## SDK Quickstart

```python
from agevidence import Client

client = Client(base_url="http://localhost:3000")

project = client.create_project(
    account_name="Northstar Methane Systems Sandbox",
    project_name="Enterprise dairy pilot",
    target_claim="The intervention reduces enteric methane.",
)

source = client.submit_source_record(
    project_id=project.id,
    document_id="trial-report-001",
    evidence_type="evidence.trial_report",
    controlled_uri="evidence://trial-report-001",
    commitment="sha256:demo",
)

run = client.run_model(project_id=project.id)
candidate = run.candidates[0]

client.review_candidate(
    candidate_id=candidate.id,
    decision="accepted",
    reason="Source reference supports this candidate.",
)

quote = client.create_quote(
    project_id=project.id,
    product_code="verification_readiness_cycle",
    scope={"evidence_classes": 4, "source_systems": 2, "countries": 1},
)

order = client.create_order(quote_id=quote.quote_id)
paid = client.checkout_order(order_id=order.order_id)
artifact = client.build_artifact(project_id=project.id, order_id=paid.order_id)

print(artifact.artifact.verification_command)
```

Model output is candidate evidence only. It cannot approve methods, certify
reductions, determine claim ownership, or create institutional reliance.

The v1 client also exposes resource namespaces. Existing top-level methods are
kept as compatibility aliases:

```python
from agevidence import Client

with Client(base_url="http://localhost:3000", api_token="token") as client:
    adapters = client.country.list_adapters()
    project = client.projects.create(
        account_name="Northstar Methane Systems Sandbox",
        project_name="Enterprise dairy pilot",
        target_claim="The intervention reduces enteric methane.",
    )
```

Mutating requests accept idempotency keys on resource methods when retrying a
POST, PATCH or checkout operation is intended.

## Async Client

HTTP SDK calls are also available through `AsyncClient`:

```python
from agevidence import AsyncClient

async with AsyncClient(base_url="http://localhost:3000") as client:
    adapters = await client.country.list_adapters()
```

The async client mirrors the sync resource namespaces. Verifier delegation stays
sync-only and still shells out to the configured Rust verifier.

## CLI Quickstart

```bash
agevidence project create \
  --account-name "Northstar Methane Systems Sandbox" \
  --name "Enterprise dairy pilot" \
  --target-claim "The intervention reduces enteric methane."
```

```bash
agevidence source add \
  --project-id PROJECT_ID \
  --document-id trial-report-001 \
  --evidence-type evidence.trial_report \
  --controlled-uri evidence://trial-report-001 \
  --commitment sha256:demo
```

```bash
agevidence model run --project-id PROJECT_ID
agevidence review --candidate-id CANDIDATE_ID --decision accepted --reason "Source reference supports this candidate."
agevidence quote create --project-id PROJECT_ID --product-code verification_readiness_cycle
agevidence order create --quote-id QUOTE_ID
agevidence order checkout --order-id ORDER_ID
agevidence artifact build --project-id PROJECT_ID --order-id ORDER_ID
```

## Project 4030 Replay

Project 4030 is the synthetic Australian beef-style integration fixture.

```bash
AGEVIDENCE_INTEGRATION_SOURCE=athian_salesforce_production \
AGEVIDENCE_INTEGRATION_SECRET=demo-integration-secret \
agevidence replay project-4030
```

The CLI signs each event with HMAC-SHA256 for integration authentication and
submits it to `/v1/integrations/events`.

Integration event signing is not receipt signing. The SDK does not issue or
sign receipts.

## Local Verification Delegation

Configure the Rust verifier command:

```bash
agevidence login --base-url http://localhost:3000 --verifier-command "target/debug/baink-cli"
```

Then delegate verification:

```bash
agevidence verify --bundle bundle.zip
```

If the verifier command is missing, the CLI returns a setup error instead of
trying to implement bundle verification in Python.

## SDK Organization

The SDK is organized around capabilities, not separate industry SDKs:

```text
agevidence
  core
  evidence
  source_records
  events
  receipts
  verification
  adapters
  identifiers
  sources
  policies
  countries
  authorities
  exports
  models
  client_resources
  async_client
  cli
  country_cli
  campaign_cli
  plugins
  livestock
```

Country adapters are executable Python runtime classes backed by packaged
manifest snapshots for adapter identity, method metadata, requirements and
limitations. YAML files never load arbitrary Python code. Entry-point adapters
must be installed through the `agevidence.country_adapters` Python entry-point
group, and local development adapters must be explicitly loaded as
`module:object`.

Current country facts:

* AU and CA are active executable adapters.
* NZ remains scaffold.
* UK and EU remain research.
* `au_mla` remains a placeholder until a concrete source contract exists.

Adapter output does not claim certification, endorsement, conformance,
government approval, production integration or receipt validity.

## Campaign Namespace

Campaign Control Plane methods live under `client.campaign` and the
`agevidence campaign ...` CLI group. Campaign headers are sent separately from
event payloads:

```text
X-AgEvidence-Campaign-Account
X-AgEvidence-Activation
X-AgEvidence-Repository-SHA
X-AgEvidence-SDK-Version
```

Sandbox campaign handoff values are planning signals only. They are not booked,
collected or recognized revenue.

## Package Contract

The package ships a `py.typed` marker for Python 3.11+ type consumers. Request
models are strict about unknown fields; response models remain additive so the
Rails `/v1` scaffold can add compatible fields without breaking SDK consumers.

## Test

```bash
cd sdks/python
python3 -m pytest
```
