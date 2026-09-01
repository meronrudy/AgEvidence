"""Country adapter CLI commands."""

from __future__ import annotations

import json
from pathlib import Path

import typer

from agevidence.adapters.registry import default_registry
from agevidence.cli_support import client_factory as _client
from agevidence.cli_support import emit as _emit
from agevidence.cli_support import handle_error as _handle_error
from agevidence.sources.models import SourceRecordInput

adapter_app = typer.Typer(help="Country adapter commands")
identifier_app = typer.Typer(help="Local identifier commands")
sources_app = typer.Typer(help="Country source normalization commands")
country_app = typer.Typer(help="Country determination commands")
fixtures_app = typer.Typer(help="Country adapter fixture commands")


def register_country_cli(app: typer.Typer) -> None:
    """Register country adapter command groups on the root CLI."""

    app.add_typer(adapter_app, name="adapters")
    app.add_typer(identifier_app, name="identifiers")
    app.add_typer(sources_app, name="sources")
    app.add_typer(country_app, name="country")
    app.add_typer(fixtures_app, name="fixtures")



def _registry():
    return default_registry()


def _country_adapter(value: str):
    return _registry().resolve(value)


@adapter_app.command("list")
def adapters_list(output: str = typer.Option("json", "--format")) -> None:
    """List locally executable country adapters."""

    try:
        adapters = [
            adapter.metadata.model_dump(mode="json", exclude_none=True)
            | {
                "method_id": adapter.method_id,
                "method_version": adapter.method_version,
                "authority": adapter.authority,
            }
            for adapter in _registry().all()
        ]
        _emit({"adapters": adapters}, output)
    except Exception as exc:
        _handle_error(exc)


@adapter_app.command("show")
def adapters_show(adapter: str = typer.Argument(...), output: str = typer.Option("json", "--format")) -> None:
    """Show a locally executable country adapter."""

    try:
        resolved = _country_adapter(adapter)
        _emit(
            resolved.metadata.model_dump(mode="json", exclude_none=True)
            | {
                "method_id": resolved.method_id,
                "method_version": resolved.method_version,
                "authority": resolved.authority,
                "evidence_requirements": resolved.evidence_requirements({}),
                "policy_stack": [entry.model_dump(mode="json", exclude_none=True) for entry in resolved.policy_stack()],
            },
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@adapter_app.command("validate")
def adapters_validate(adapter: str = typer.Argument(...), remote: bool = typer.Option(False), output: str = typer.Option("json", "--format")) -> None:
    """Validate a local adapter or the Rails manifest projection."""

    try:
        if remote:
            _emit(_client().validate_country_adapter(adapter), output)
            return
        resolved = _country_adapter(adapter)
        _emit(
            {
                "adapter_id": resolved.metadata.id,
                "country_code": resolved.metadata.country_code,
                "status": resolved.metadata.status,
                "classification": resolved.metadata.status,
                "errors": [],
                "authority_boundary": "Adapter validation does not approve or certify evidence.",
            },
            output,
        )
    except Exception as exc:
        _handle_error(exc)


@identifier_app.command("normalize")
def identifiers_normalize(
    adapter: str = typer.Argument(...),
    identifier_system: str = typer.Argument(...),
    value: str = typer.Argument(...),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Normalize a local identifier with a country adapter."""

    try:
        _emit(_country_adapter(adapter).normalize_identifier(identifier_system, value), output)
    except Exception as exc:
        _handle_error(exc)


@sources_app.command("normalize")
def sources_normalize(
    adapter: str = typer.Argument(...),
    source_profile: str = typer.Argument(...),
    record: Path = typer.Argument(..., exists=True),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Normalize a local source record with a country adapter."""

    try:
        payload = json.loads(record.read_text(encoding="utf-8"))
        _emit(_country_adapter(adapter).normalize_source_record(source_profile, payload), output)
    except Exception as exc:
        _handle_error(exc)


@sources_app.command("check")
def sources_check(
    adapter: str = typer.Argument(...),
    check_id: str = typer.Argument(...),
    reference: Path = typer.Argument(..., exists=True),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Run or describe an external source check."""

    try:
        payload = json.loads(reference.read_text(encoding="utf-8"))
        _emit(_country_adapter(adapter).external_checks(check_id, payload), output)
    except Exception as exc:
        _handle_error(exc)


@country_app.command("evaluate")
def country_evaluate(
    project_id: str = typer.Argument(...),
    adapter: str = typer.Option(..., "--adapter", help="Country code or adapter id."),
    institution_profile: Path | None = typer.Option(None, exists=True),
    output: str = typer.Option("json", "--format"),
) -> None:
    """Append a Rails country determination through the Developer OS API."""

    try:
        profile = json.loads(institution_profile.read_text(encoding="utf-8")) if institution_profile else None
        _emit(_client().create_country_determination(project_id=project_id, adapter=adapter, institution_profile=profile), output)
    except Exception as exc:
        _handle_error(exc)


@fixtures_app.command("run")
def fixtures_run(adapter: str = typer.Argument(...), output: str = typer.Option("json", "--format")) -> None:
    """Run a local synthetic country adapter fixture."""

    try:
        resolved = _country_adapter(adapter)
        result = resolved.evaluate(
            project_id="project-fixture",
            evidence_graph_root="sha256:fixture-root",
            country_context={"species": "species.beef_cattle"},
            source_records=[
                SourceRecordInput(
                    source_system="agevidence_fixture",
                    source_profile="animal_cohort",
                    record={"document_id": "fixture-animal-cohort", "commitment": "sha256:fixture-animal-cohort"},
                    commitment="sha256:fixture-animal-cohort",
                ),
                SourceRecordInput(
                    source_system="agevidence_fixture",
                    source_profile="intervention_delivery",
                    record={"document_id": "fixture-intervention", "commitment": "sha256:fixture-intervention"},
                    commitment="sha256:fixture-intervention",
                ),
            ],
        )
        _emit(result, output)
    except Exception as exc:
        _handle_error(exc)
