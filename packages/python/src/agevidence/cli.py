"""Command line interface for the AgEvidence Python SDK."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import typer
from rich.console import Console
from rich.table import Table

from .client import Client
from .config import SDKConfig
from .errors import AgEvidenceError
from .events import load_event, project_4030_event_files, sign_hmac_event
from .verification import Verifier

app = typer.Typer(help="AgEvidence Developer OS CLI")
project_app = typer.Typer(help="Project commands")
source_app = typer.Typer(help="Source-record commands")
model_app = typer.Typer(help="Model-run commands")
pricing_app = typer.Typer(help="Pricing commands")
quote_app = typer.Typer(help="Quote commands")
order_app = typer.Typer(help="Artifact order commands")
artifact_app = typer.Typer(help="Artifact commands")
operation_app = typer.Typer(help="Operation commands")
event_app = typer.Typer(help="Evidence Event Inbox commands")
replay_app = typer.Typer(help="Replay fixture scenarios")

app.add_typer(project_app, name="project")
app.add_typer(source_app, name="source")
app.add_typer(model_app, name="model")
app.add_typer(pricing_app, name="pricing")
app.add_typer(quote_app, name="quote")
app.add_typer(order_app, name="order")
app.add_typer(artifact_app, name="artifact")
app.add_typer(operation_app, name="operation")
app.add_typer(event_app, name="event")
app.add_typer(replay_app, name="replay")

console = Console()


def _client(base_url: str | None = None) -> Client:
    return Client(base_url=base_url)


def _payload(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json", exclude_none=True)
    return value


def _emit(value: Any, output: str = "json") -> None:
    payload = _payload(value)
    if output == "json":
        console.print_json(data=payload)
        return

    if isinstance(payload, dict):
        table = Table(show_header=True, header_style="bold")
        table.add_column("Field")
        table.add_column("Value")
        for key, item in payload.items():
            table.add_row(str(key), json.dumps(item) if isinstance(item, (dict, list)) else str(item))
        console.print(table)
        return

    console.print(payload)


def _handle_error(exc: Exception) -> None:
    if isinstance(exc, AgEvidenceError):
        console.print(f"[red]{exc}[/red]", file=sys.stderr)
        raise typer.Exit(code=1)
    raise exc


@app.command()
def login(
    base_url: str = typer.Option("http://localhost:3000", help="Rails Developer OS base URL."),
    api_token: str | None = typer.Option(None, help="Reserved for future authenticated deployments."),
    integration_source: str | None = typer.Option(None, help="Default integration source for event commands."),
    verifier_command: str | None = typer.Option(None, help="External verifier command, for example target/debug/baink-cli."),
) -> None:
    """Write local CLI configuration."""

    path = SDKConfig(
        base_url=base_url,
        api_token=api_token,
        integration_source=integration_source,
        verifier_command=verifier_command,
    ).save()
    console.print(f"Saved AgEvidence config to {path}")


@project_app.command("create")
def project_create(
    account_name: str = typer.Option(...),
    name: str = typer.Option(...),
    target_claim: str = typer.Option(...),
    funding_stage: str = typer.Option("sandbox"),
    project_type: str = typer.Option("intervention"),
    external_project_id: str | None = typer.Option(None),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().create_project(
                account_name=account_name,
                project_name=name,
                target_claim=target_claim,
                funding_stage=funding_stage,
                project_type=project_type,
                external_project_id=external_project_id,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@source_app.command("add")
def source_add(
    project_id: str = typer.Option(...),
    document_id: str = typer.Option(...),
    evidence_type: str = typer.Option(...),
    controlled_uri: str = typer.Option(...),
    commitment: str = typer.Option(...),
    source_system: str = typer.Option("agevidence_cli"),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().submit_source_record(
                project_id=project_id,
                document_id=document_id,
                evidence_type=evidence_type,
                controlled_uri=controlled_uri,
                commitment=commitment,
                source_system=source_system,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@model_app.command("run")
def model_run(project_id: str = typer.Option(...), adapter_id: str = typer.Option("qwen3.5-4b-reference"), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().run_model(project_id=project_id, adapter_id=adapter_id), output)
    except Exception as exc:
        _handle_error(exc)


@app.command()
def review(
    candidate_id: str = typer.Option(...),
    decision: str = typer.Option(...),
    reason: str = typer.Option(...),
    reviewer_role: str = typer.Option("scientific_reviewer_sandbox"),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().review_candidate(candidate_id=candidate_id, decision=decision, reason=reason, reviewer_role=reviewer_role), output)
    except Exception as exc:
        _handle_error(exc)


@pricing_app.command("products")
def pricing_products(output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().list_products(), output)
    except Exception as exc:
        _handle_error(exc)


@quote_app.command("create")
def quote_create(
    project_id: str = typer.Option(...),
    product_code: str = typer.Option(...),
    scope_json: str = typer.Option("{}", help="JSON object of pricing scope factors."),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().create_quote(project_id=project_id, product_code=product_code, scope=json.loads(scope_json)), output)
    except Exception as exc:
        _handle_error(exc)


@order_app.command("create")
def order_create(quote_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().create_order(quote_id=quote_id), output)
    except Exception as exc:
        _handle_error(exc)


@order_app.command("checkout")
def order_checkout(order_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().checkout_order(order_id=order_id), output)
    except Exception as exc:
        _handle_error(exc)


@artifact_app.command("build")
def artifact_build(
    project_id: str = typer.Option(...),
    order_id: str | None = typer.Option(None),
    quote_id: str | None = typer.Option(None),
    product_code: str | None = typer.Option(None),
    sandbox_checkout: bool = typer.Option(False),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(
            _client().build_artifact(
                project_id=project_id,
                order_id=order_id,
                quote_id=quote_id,
                product_code=product_code,
                sandbox_checkout=sandbox_checkout,
            ),
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@artifact_app.command("show")
def artifact_show(project_id: str = typer.Option(...), artifact_id: str = typer.Option(...), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().get_artifact(project_id=project_id, artifact_id=artifact_id), output)
    except Exception as exc:
        _handle_error(exc)


@operation_app.command("wait")
def operation_wait(operation_id: str = typer.Option(...), timeout: float = typer.Option(60.0), interval: float = typer.Option(2.0), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().wait_for_operation(operation_id, timeout=timeout, interval=interval), output)
    except Exception as exc:
        _handle_error(exc)


@event_app.command("submit")
def event_submit(
    file: Path = typer.Option(..., exists=True),
    source: str = typer.Option(...),
    timestamp: str = typer.Option(...),
    signature: str = typer.Option(...),
    output: str = typer.Option("json", "--format"),
) -> None:
    try:
        _emit(_client().submit_event(load_event(file), source=source, timestamp=timestamp, signature=signature), output)
    except Exception as exc:
        _handle_error(exc)


@event_app.command("replay")
def event_replay(event_id: str = typer.Option(...), source: str | None = typer.Option(None), reason: str = typer.Option("agevidence_cli_replay"), output: str = typer.Option("json", "--format")) -> None:
    try:
        _emit(_client().replay_event(event_id, source=source, reason=reason), output)
    except Exception as exc:
        _handle_error(exc)


@replay_app.command("project-4030")
def replay_project_4030(
    fixture_root: Path | None = typer.Option(None, help="Override Project 4030 fixture directory."),
    source: str | None = typer.Option(None),
    secret: str | None = typer.Option(None),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Sign and replay the eight-event Project 4030 scenario."""

    config = SDKConfig.load()
    source_key = source or config.integration_source or "athian_salesforce_production"
    signing_secret = secret or config.integration_secret or "demo-integration-secret"
    client = _client()
    results = []
    try:
        for path in project_4030_event_files(fixture_root):
            event = sign_hmac_event(load_event(path), source=source_key, secret=signing_secret)
            submitted = client.submit_event(
                event,
                source=source_key,
                timestamp=event["occurred_at"],
                signature=event["integrity"]["signature"],
            )
            results.append({"file": path.name, **submitted.model_dump(mode="json", exclude_none=True)})
        _emit({"events": results}, output)
    except Exception as exc:
        _handle_error(exc)


@app.command()
def verify(bundle: Path = typer.Option(..., exists=False)) -> None:
    """Delegate bundle verification to the configured Rust verifier."""

    try:
        _emit(Verifier().verify_bundle(bundle), "json")
    except Exception as exc:
        _handle_error(exc)


if __name__ == "__main__":
    app()
